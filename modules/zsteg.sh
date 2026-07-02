MD_NAME="Zsteg"
MD_DESC="LSB detection for PNG/BMP"
MD_TYPES="png bmp"
MD_DEPS="zsteg"
MD_PRIORITY=30
MD_PRODUCES="lsb_data flag"

analyze_zsteg() {
    local f="$1"
    header "Zsteg" "LSB Analysis"
    if command -v zsteg &>/dev/null; then
        if $VERBOSE; then zsteg -a "$f" 2>/dev/null
        else
            while IFS= read -r l; do
                l=$(echo "$l" | tr -d '\r')
                echo "$l" | grep -qE '\.\. *$' && continue
                echo "$l" | grep -q '\.\. file:' && continue
                local b64=$(echo "$l" | grep -oE '[A-Za-z0-9+/]{30,}={0,2}' | head -1)
                if [ -n "$b64" ]; then
                    local d=$(echo "$b64" | base64 -d 2>/dev/null)
                    if [ -n "$d" ] && echo "$d" | grep -qiE "flag|ctf|ncse|pico|secret" 2>/dev/null; then
                        emit "flag" "FLAG: $d"
                        continue
                    fi
                fi
                echo "  $l"
            done <<< "$(zsteg "$f" 2>/dev/null)"
        fi
    else info "zsteg not installed"; fi
}
