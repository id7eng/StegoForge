MD_NAME="Snow"
MD_DESC="Whitespace steganography decoder"
MD_TYPES="txt text html css js"
MD_DEPS="snow"
MD_PRIORITY=32
MD_PRODUCES="snow_data flag"

analyze_snow() {
    local f="$1"
    header "Snow" "Whitespace Analysis"

    local out=$(run_cmd snow -C "$f")
    local line=$(echo "$out" | grep -v "error\|usage\|^$" | head -1)
    [ -n "$line" ] && emit "snow_data" "Snow data: $line"

    # Try with passwords from config
    local pwlist=""
    [ -f "${CONFIG_DIR}/passwords.conf" ] && pwlist="${CONFIG_DIR}/passwords.conf"
    if [ -n "$pwlist" ]; then
        while IFS= read -r p; do
            [ -z "$p" ] && continue
            local result=$(run_cmd snow -C -p "$p" "$f")
            local data=$(echo "$result" | grep -v "error\|usage\|^$" | head -1)
            [ -n "$data" ] && {
                emit "password" "Snow password: $p"
                emit "snow_data" "$data"
                return
            }
        done < "$pwlist"
    fi
}
