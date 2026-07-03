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

    # Stream strings output through a temp file instead of loading into memory
    local tmp_str=$(mktemp)
    LC_ALL=C strings "$f" 2>/dev/null | tr -d '\0' > "$tmp_str"

    while read l; do
        emit "keyword" "Keyword: $l"
    done < <(grep -iE "$kw" "$tmp_str")

    while read b64; do
        local d=$(echo "$b64" | base64 -d 2>/dev/null | tr -d '\0')
        [ -n "$d" ] && echo "$d" | grep -qiE "$kw" 2>/dev/null && emit "base64_string" "Base64: $d"
    done < <(grep -oE '[A-Za-z0-9+/]{20,}={0,2}' "$tmp_str" || true)

    local combined=""
    for p in "${FLAG_PATTERNS[@]}"; do
        [ -n "$combined" ] && combined+="|"
        combined+="$p"
    done
    [ -n "$combined" ] && while read m; do
        [ -n "$m" ] && emit "flag" "$m"
    done < <(grep -oP "$combined" "$tmp_str" 2>/dev/null)

    # Hex string decode: detect long hex strings and decode to check for flags
    local hex_pat='[0-9a-fA-F]{40,}'
    while read h; do
        [ -z "$h" ] && continue
        local dec=$(echo "$h" | xxd -r -p 2>/dev/null | tr -d '\0')
        [ -n "$dec" ] && for p in "${FLAG_PATTERNS[@]}"; do
            if echo "$dec" | grep -oP "$p" 2>/dev/null; then
                emit "flag" "$dec"
                break
            fi
        done
    done < <(grep -oE "$hex_pat" "$tmp_str" 2>/dev/null)

    # Partial flag detection: flag fragments ending with }
    while read partial; do
        [ -z "$partial" ] && continue
        emit "partial_flag" "Partial: $partial"
    done < <(grep -oP '(?<![A-Za-z0-9_])[A-Za-z0-9_!@#$%^&*()+\-]{6,}\{[^}]{1,200}\}' "$tmp_str" 2>/dev/null)

    # Flag tail detection: content after { ending with }
    while read tail; do
        [ -z "$tail" ] && continue
        emit "partial_flag" "Tail: $tail"
    done < <(grep -oP '[a-zA-Z0-9_!@#$%^&*()+\-]{6,}\}' "$tmp_str" 2>/dev/null)

    rm -f "$tmp_str"
}
