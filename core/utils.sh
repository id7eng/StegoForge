_figlet_logo() {
    cat <<'STEGOEOF'
   _____ __                   ______                    
  / ___// /____  ____ _____  / ____/___  _________ ____ 
  \__ \/ __/ _ \/ __ `/ __ \/ /_  / __ \/ ___/ __ `/ _ \ 
 ___/ / /_/  __/ /_/ / /_/ / __/ / /_/ / /  / /_/ /  __/
/____/\__/\___/\__, /\____/_/    \____/_/   \__, /\___/ 
              /____/                       /____/       
STEGOEOF
}

banner() {
    [ "$QUIET" = true ] && return
    echo -e "${C}╔══════════════════════════════════════════════╗${N}"
    echo -e "${C}║        ${W}StegoForge v${VERSION}${C} - CTF Toolkit        ║${N}"
    echo -e "${C}║   ${DIM}Steganography & Forensics Toolkit${C}        ║${N}"
    echo -e "${C}╚══════════════════════════════════════════════╝${N}"
}

usage() {
    echo ""
    while IFS= read -r line; do
        echo -e "${W}$line${N}"
    done <<< "$(_figlet_logo)"
    echo ""

    echo -e "  ${BOLD}SYNOPSIS${N}"
    echo -e "  ${C}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}"
    echo -e "    ${W}stegoforge${N} [${W}options${N}] ${B}<file|directory>${N}"
    echo -e "    ${W}stegoforge knowledge${N} ${B}<command>${N} [${B}args${N}]"
    echo ""

    echo -e "  ${BOLD}SCAN COMMANDS${N}"
    echo -e "  ${C}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}"
    echo -e "    ${W}stegoforge${N} ${B}<file>${N}              Analyze a file for hidden data"
    echo -e "    ${W}stegoforge -r${N} ${B}<dir>${N}             Recursively scan a directory"
    echo ""

    echo -e "  ${BOLD}KNOWLEDGE COMMANDS${N}"
    echo -e "  ${C}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}"
    echo -e "    ${W}init${N}                    Initialize knowledge database"
    echo -e "    ${W}sync${N}                    Sync all sources (up to 10 writeups)"
    echo -e "    ${W}sync --auto${N}             Add default sources then sync"
    echo -e "    ${W}sync-source${N} ${B}<id>${N}         Sync a specific source"
    echo -e "    ${W}import${N} ${B}<path>${N}             Import local writeups (md/html/pdf/txt)"
    echo -e "    ${W}add-source${N}              Add a new knowledge source interactively"
    echo -e "    ${W}list-sources${N}            List all configured sources"
    echo -e "    ${W}remove-source${N} ${B}<id>${N}        Remove a source"
    echo -e "    ${W}info${N}                    Show knowledge base statistics"
    echo -e "    ${W}search${N} ${B}<term>${N}             Search the knowledge base"
    echo -e "    ${W}suggest${N} ${B}<file>${N}            Suggest workflow based on KB"
    echo -e "    ${W}evidence${N} [${B}session${N}]         Show decision reasoning evidence"
    echo -e "    ${W}stats${N} [${B}file_type${N}]         Show tool success statistics"
    echo -e "    ${W}connectors${N}              List available connector types"
    echo -e "    ${W}setup-auto-sync${N}         Set up daily cron sync"
    echo -e "    ${W}setup-login-sync${N}         Set up sync on login"
    echo -e "    ${W}stop-auto${N}                Stop automatic sync"
    echo -e "    ${W}auto-status${N}              Show auto-sync status"
    echo -e "    ${W}auto-defaults${N}            Add default sources and sync"
    echo -e "    ${W}prune${N}                   Knowledge base maintenance"
    echo ""

    echo -e "  ${BOLD}OUTPUT MODES${N}"
    echo -e "  ${C}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}"
    echo -e "    ${W}normal${N}         Only the final flag result"
    echo -e "    ${W}-v${N}             Show module progress live"
    echo -e "    ${W}-vv${N}            Show every command executed"
    echo -e "    ${W}--json${N}          JSON output for scripting"
    echo -e "    ${W}--summary${N}       One-line summary per file"
    echo ""

    echo -e "  ${BOLD}SCAN OPTIONS${N}"
    echo -e "  ${C}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}"
    echo -e "    ${W}-v, --verbose${N}        Show module output while scanning"
    echo -e "    ${W}-vv${N}                     Show every external command"
    echo -e "    ${W}-r, --recursive${N}      Scan directories recursively"
    echo -e "    ${W}-o${N} ${B}<dir>${N}              Custom output directory"
    echo -e "    ${W}-w${N} ${B}<file>${N}             Wordlist for brute-force attacks"
    echo -e "    ${W}-l, --list${N}          List all modules with priorities"
    echo -e "    ${W}--json${N}               Output results as JSON"
    echo -e "    ${W}--summary${N}            Compact one-line output"
    echo -e "    ${W}--readonly${N}           Work on a copy, don't modify original"
    echo -e "    ${W}--docker${N}             Force Docker execution"
    echo -e "    ${W}--doctor${N}             Check system dependencies"
    echo -e "    ${W}-h, --help${N}          Show this help message"
    echo ""

    echo -e "  ${BOLD}EXAMPLES${N}"
    echo -e "  ${C}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}"
    echo -e "    ${W}stegoforge image.png${N}"
    echo -e "      → Analyze and show the flag"
    echo ""
    echo -e "    ${W}stegoforge -v image.jpg${N}"
    echo -e "      → Analyze with live module progress"
    echo ""
    echo -e "    ${W}stegoforge --json -r ~/challenges/${N}"
    echo -e "      → Recursive scan, JSON output"
    echo ""
    echo -e "    ${W}stegoforge -w rockyou.txt image.jpg${N}"
    echo -e "      → Use wordlist for brute-force"
    echo ""
    echo -e "    ${W}stegoforge knowledge sync --auto${N}"
    echo -e "      → Add default sources and fetch 10 writeups"
    echo ""
    echo -e "    ${W}stegoforge knowledge suggest file.png${N}"
    echo -e "      → Get KB-based analysis recommendations"
    echo ""

    echo -e "  ${BOLD}MODULES${N}"
    echo -e "  ${C}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}"
    echo -e "    49 analysis modules — use ${W}stegoforge -l${N} to list them"
    echo -e "    Priority-based execution • File-type filtering • Pipeline triggers"
    echo ""

    echo -e "  ${BOLD}FILES${N}"
    echo -e "  ${C}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}"
    echo -e "    ${B}output/sessions/PID/${N}          Session output directory"
    echo -e "    ${B}output/sessions/PID/carved/${N}   Extracted/carved files"
    echo -e "    ${B}knowledge/knowledge.db${N}        SQLite knowledge base"
    echo -e "    ${B}config/priority_rules.json${N}    Priority configuration"
    echo -e "    ${B}config/pipeline.conf${N}          Pipeline rules"
    echo ""

    echo -e "  ${C}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}"
    echo -e "  ${DIM}Report issues: https://github.com/id7eng/StegoForge/issues${N}"
    echo -e "  ${DIM}StegoForge v${VERSION} — Steganography & Forensics Toolkit${N}"
    echo ""
    exit 0
}

get_file_type() {
    local f="$1"
    local raw=$(file -b "$f" 2>/dev/null)
    local lower=$(echo "$raw" | tr '[:upper:]' '[:lower:]')
    # Normalize common text types for module type matching
    lower=$(echo "$lower" | sed 's/^ascii /text /; s/^unicode /text /; s/^utf-8 /text /; s/^iso-8859 /text /; s/^non-iso extended-ascii /text /')
    [ "$lower" = "data" ] || [ "$lower" = "application/octet-stream" ] && {
        local magic=$(xxd -l 8 -p "$f" 2>/dev/null)
        case "$magic" in
            89504e47*) echo "png image data"; return ;;
            ffd8ffe0*|ffd8ffe1*|ffd8ffe2*|ffd8ffdb*|ffd8ffc0*|ffd8ffc2*|ffd8ffc4*|ffd8ffc8*|ffd8fffe*) echo "jpeg image data"; return ;;
            424d*) echo "bmp image data"; return ;;
            504b0304*) echo "zip archive data"; return ;;
        esac
    }
    echo "$lower"
}


