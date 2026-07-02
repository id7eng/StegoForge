[ -z "$TOOL_DIR" ] && {
    SELF="${BASH_SOURCE[0]}"
    while [ -h "$SELF" ]; do SELF="$(readlink "$SELF")"; done
    TOOL_DIR="$(cd -P "$(dirname "$SELF")/.." && pwd)"
}
CORE_DIR="${TOOL_DIR}/core"
MODULES_DIR="${TOOL_DIR}/modules"
CONFIG_DIR="${TOOL_DIR}/config"
OUTPUT_DIR="${TOOL_DIR}/output"

source "${CORE_DIR}/logger.sh"
source "${CORE_DIR}/utils.sh"
source "${CORE_DIR}/flags.sh"
source "${CORE_DIR}/dependency.sh"

VERSION="1.3.0"
QUIET=true
OUTDIR=""; RECURSIVE=false; VERBOSE=false; JSON=false
REPORT_FILE=""; TARGET=""; WORDLIST=""
FINDINGS=()
EMITTED=()

declare -a MODULE_NAMES MODULE_PRIORITY_ORDER
declare -A MODULE_DISPLAY MODULE_TYPES MODULE_DEPS MODULE_PRIORITY MODULE_PRODUCES MODULE_TRIGGERS

# ─────────────────────────────────────────────
# MODULE LOADER
# ─────────────────────────────────────────────
load_modules() {
    MODULE_NAMES=()
    MODULE_PRIORITY_ORDER=()
    for mod in "$MODULES_DIR"/*.sh; do
        [ -f "$mod" ] || continue
        local base=$(basename "$mod" .sh)
        MODULE_NAMES+=("$base")
        source "$mod"
        MODULE_DISPLAY["$base"]="${MD_NAME:-$base}"
        MODULE_TYPES["$base"]="${MD_TYPES:-*}"
        MODULE_DEPS["$base"]="${MD_DEPS:-}"
        MODULE_PRIORITY["$base"]="${MD_PRIORITY:-50}"
        MODULE_PRODUCES["$base"]="${MD_PRODUCES:-}"
        MODULE_TRIGGERS["$base"]="${MD_TRIGGERS:-}"
    done

    MODULE_PRIORITY_ORDER=($(
        for name in "${MODULE_NAMES[@]}"; do
            echo "${MODULE_PRIORITY[$name]}:$name"
        done | sort -t: -k1 -n | cut -d: -f2
    ))
}

list_modules() {
    load_flag_patterns
    echo -e "\n${BOLD}Available Modules (${#MODULE_NAMES[@]}):${N}"
    echo -e "${DIM}──────────────────────────────────────────────────────${N}"
    printf "  ${BOLD}%-6s %-18s %-25s %s${N}\n" "PRIO" "NAME" "TYPES" "PRODUCES"
    echo -e "${DIM}──────────────────────────────────────────────────────${N}"
    for name in "${MODULE_PRIORITY_ORDER[@]}"; do
        local prio="${MODULE_PRIORITY[$name]}"
        local display="${MODULE_DISPLAY[$name]}"
        local types="${MODULE_TYPES[$name]}"
        local produces="${MODULE_PRODUCES[$name]:--}"
        printf "  %-6s ${W}%-18s${N} ${B}%-25s${N} %s\n" "$prio" "$display" "$types" "$produces"
    done
    echo ""
    echo -e "${BOLD}Active Flag Patterns:${N}"
    for p in "${FLAG_PATTERNS[@]}"; do echo "  ${DIM}•${N} $p"; done
    exit 0
}

# ─────────────────────────────────────────────
# WORKFLOW ENGINE
# ─────────────────────────────────────────────
run_workflow() {
    local f="$1" wl="$2"
    local -a run_queue run_done

    run_queue=("${MODULE_PRIORITY_ORDER[@]}")
    run_done=()

    local max_iter=50
    while [ ${#run_queue[@]} -gt 0 ] && [ $max_iter -gt 0 ]; do
        local name="${run_queue[0]}"
        run_queue=("${run_queue[@]:1}")

        [[ " ${run_done[@]} " =~ " $name " ]] && continue
        run_done+=("$name")

        local ftype_raw=$(get_file_type "$f")
        local types="${MODULE_TYPES[$name]:-}"

        local should_run=false
        [[ "$types" == "*" ]] && should_run=true || {
            local ftype_first=$(echo "$ftype_raw" | awk '{print tolower($1)}')
            for t in $types; do
                if [ "$t" = "data" ]; then
                    [ "$ftype_first" = "data" ] && { should_run=true; break; }
                else
                    echo "$ftype_raw" | grep -qw "$t" 2>/dev/null && { should_run=true; break; }
                fi
            done
        }

        if $should_run; then
            [ "$QUIET" = false ] && echo -e "\n${C}── ${W}${MODULE_DISPLAY[$name]}${N}${C} ──${N}"
            if command -v "analyze_$name" &>/dev/null 2>&1; then
                "analyze_$name" "$f" "$wl"
            fi

            # Process triggers
            for ev in "${EMITTED[@]}"; do
                local ev_type="${ev%%:*}"
                for n in "${run_queue[@]}"; do
                    local triggers="${MODULE_TRIGGERS[$n]:-}"
                    if [[ " $triggers " =~ " $ev_type " ]]; then
                        [[ " ${run_done[@]} " =~ " $n " ]] && continue
                        local priority_n="${MODULE_PRIORITY[$n]:-50}"
                        local priority_n_ext="${MODULE_PRIORITY[$n]:-50}"
                        # Re-prioritize: insert earlier
                        run_queue=("$n" "${run_queue[@]}")
                    fi
                done
            done
        fi

        : $((max_iter--))
    done
}

# ─────────────────────────────────────────────
# ANALYZER
# ─────────────────────────────────────────────
analyze_file() {
    local f="$1" wl="$2"
    local ftype_raw=$(get_file_type "$f")

    if [ "$QUIET" = true ]; then exec 3>&1; exec 1>/dev/null; fi

    echo -e "\n${C}══════════════════════════════════════════════${N}"
    echo -e "${W}  File:${N} $f"
    echo -e "${W}  Type:${N} ${ftype_raw%%,*}"
    echo -e "${C}══════════════════════════════════════════════${N}"

    header "Info" "File Info"
    echo "  MD5:    $(md5sum "$f" | cut -d' ' -f1)"
    echo "  SHA256: $(sha256sum "$f" | cut -d' ' -f1)"
    echo "  Size:   $(numfmt --to=iec $(( $(stat -c%s "$f" 2>/dev/null) )) 2>/dev/null || du -h "$f" | cut -f1)"

    run_workflow "$f" "$wl"

    [ "$QUIET" = true ] && exec 1>&3 3>&-
}

generate_report() {
    local header_msg="$1"

    if [ "$QUIET" = true ]; then
        local -A seen_flag
        local has_flag=false
        for finding in "${FINDINGS[@]}"; do
            for pattern in "${FLAG_PATTERNS[@]}"; do
                local match=$(echo "$finding" | grep -oP "$pattern" 2>/dev/null | head -1)
                if [ -n "$match" ] && [ -z "${seen_flag[$match]:-}" ]; then
                    seen_flag["$match"]=1
                    echo -e "${W}Flag:${N} ${LG}$match${N}"
                    has_flag=true
                    break
                fi
            done
        done
        $has_flag || echo -e "  ${Y}No flag found${N}"
        return
    fi

    echo -e "\n${C}╔══════════════════════════════════════════════╗${N}"
    echo -e "${C}║${W}  Analysis Complete${C}${N}"
    echo -e "${C}║${N}  $header_msg"
    echo -e "${C}║${N}"
    if [ ${#FINDINGS[@]} -gt 0 ]; then
        echo -e "${C}║${W}  Findings (${#FINDINGS[@]}):${N}"
        for f in "${FINDINGS[@]}"; do echo -e "${C}║${G}  OK${N} $f"; done
    else
        echo -e "${C}║  ${Y}No suspicious findings${N}"
    fi
    echo -e "${C}║${N}"
    echo -e "${C}║${N}  Output: ${B}$OUTDIR${N}"
    echo -e "${C}╚══════════════════════════════════════════════╝${N}"
}

# ─────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────
main() {
    load_modules
    load_flag_patterns

    while [ $# -gt 0 ]; do
        case "$1" in
            -r|--recursive) RECURSIVE=true; shift ;;
            -v|--verbose) VERBOSE=true; QUIET=false; shift ;;
            -j|--json) JSON=true; shift ;;
            -o|--output) OUTDIR="$2"; shift 2 ;;
            -w|--wordlist) WORDLIST="$2"; shift 2 ;;
            -l|--list) list_modules ;;
            --doctor) doctor ;;
            -h|--help) usage ;;
            *) TARGET="$1"; shift ;;
        esac
    done

    [ -z "$TARGET" ] && usage
    [ ! -e "$TARGET" ] && err "Path not found: $TARGET" && exit 1

    [ -z "$OUTDIR" ] && OUTDIR="${OUTPUT_DIR}/sessions/$$"
    mkdir -p "$OUTDIR" "${OUTDIR}/carved" "${OUTDIR}/bitplanes" "${OUTDIR}/spectrograms" "${OUTDIR}/repaired" "${OUTDIR}/reports"

    if [ -d "$TARGET" ]; then
        banner
        echo -e "${DIM}Target: $TARGET (directory)${N}"
        if $RECURSIVE; then
            while IFS= read -r f; do [ -f "$f" ] && analyze_file "$f" "$WORDLIST"; done < <(find "$TARGET" -type f 2>/dev/null)
        else
            for f in "$TARGET"/*; do [ -f "$f" ] && analyze_file "$f" "$WORDLIST"; done
        fi
        generate_report "Scanned: $TARGET ($(find "$TARGET" -type f 2>/dev/null | wc -l) files)"
    else
        banner
        analyze_file "$TARGET" "$WORDLIST"
        generate_report "Scanned: $(basename "$TARGET")"
    fi
}
