# ─────────────────────────────────────────────
# CLI — argument parsing, list_modules, main
# ─────────────────────────────────────────────

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

main() {
    load_modules
    load_flag_patterns
    load_confidence_weights
    de_init

    while [ $# -gt 0 ]; do
        case "$1" in
            -r|--recursive) RECURSIVE=true; shift ;;
            -v|--verbose) VERBOSE=true; QUIET=false; shift ;;
            -vv|--vv) VERBOSE=true; VERBOSE_CMD=true; QUIET=true; shift ;;
            --json) JSON=true; QUIET=true; shift ;;
            --summary) SUMMARY=true; QUIET=true; shift ;;
            --readonly) READONLY=true; shift ;;
            --docker) DOCKER_MODE=true; shift ;;
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

    load_priority_rules
    load_pipeline_rules

    if $DOCKER_MODE || ! docker_native_ok; then
        if ! docker_check; then
            err "Docker not installed. Install Docker or use native mode."
            exit 1
        fi
        if ! docker_image_exists; then
            docker_build "$TOOL_DIR" || { err "Docker build failed"; exit 1; }
        fi
        $QUIET || info "Running in Docker mode"
        docker_run_analyze "$TARGET" "$@" --outdir /output
        exit $?
    fi

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
