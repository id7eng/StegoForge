MD_NAME="QuickScan"
MD_DESC="Quick raw byte scan for flag patterns"
MD_TYPES="*"
MD_DEPS=""
MD_PRIORITY=0
MD_PRODUCES="flag"

analyze_quick_scan() {
    local f="$1"
    [ ! -f "$f" ] && return
    header "QuickScan" "Raw Flag Pattern Scan"
    local combined=""
    for p in "${FLAG_PATTERNS[@]}"; do
        [ -n "$combined" ] && combined+="|"
        combined+="$p"
    done
    [ -z "$combined" ] && return
    log_cmd_str "grep -a -oP \"$combined\" \"$f\""
    while read m; do
        [ -n "$m" ] && { emit_flag "$m"; return; }
    done < <(grep -a -oP "$combined" "$f" 2>/dev/null)
}
