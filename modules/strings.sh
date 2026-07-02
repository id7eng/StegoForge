MD_NAME="Strings"
MD_DESC="Keyword search + Base64 auto-decode + flag pattern matching"
MD_TYPES="*"
MD_DEPS="strings"
MD_PRIORITY=10
MD_PRODUCES="keyword base64_string flag"

analyze_strings() {
    local f="$1"
    header "Strings" "Keyword Analysis"
    local kw="flag|ctf|ncse|pico|secret|pass|key|http|https|ssh|BEGIN|ender|base64|PASSWORD"

    while read l; do
        emit "keyword" "Keyword: $l"
    done < <(strings "$f" 2>/dev/null | grep -iE "$kw")

    while read b64; do
        local d=$(echo "$b64" | base64 -d 2>/dev/null)
        [ -n "$d" ] && echo "$d" | grep -qiE "$kw" 2>/dev/null && emit "base64_string" "Base64: $d"
    done < <(strings "$f" 2>/dev/null | grep -oE '[A-Za-z0-9+/]{20,}={0,2}' 2>/dev/null)

    local combined=""
    for p in "${FLAG_PATTERNS[@]}"; do
        [ -n "$combined" ] && combined+="|"
        combined+="$p"
    done
    [ -n "$combined" ] && strings "$f" 2>/dev/null | grep -oP "$combined" 2>/dev/null | while read m; do
        emit "flag" "$m"
    done
}
