CONFIG_DIR="${TOOL_DIR}/config"
declare -a FLAG_PATTERNS

load_flag_patterns() {
    FLAG_PATTERNS=()
    local conf="${CONFIG_DIR}/flag_patterns.conf"
    if [ -f "$conf" ]; then
        while IFS= read -r line; do
            [[ "$line" =~ ^#.*$ ]] || [ -z "$line" ] && continue
            FLAG_PATTERNS+=("$line")
        done < "$conf"
    fi
    [ ${#FLAG_PATTERNS[@]} -eq 0 ] && FLAG_PATTERNS=(
        "[A-Za-z0-9_!@#$%^&*(){}]{10,}"
    )
}

extract_flags() {
    local text="$1"
    for p in "${FLAG_PATTERNS[@]}"; do
        echo "$text" | grep -oP "$p" 2>/dev/null
    done
}
