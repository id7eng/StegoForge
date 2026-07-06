MD_NAME="Metadata"
MD_DESC="EXIF metadata + acrostic detection"
MD_TYPES="jpg jpeg png bmp gif tiff webp"
MD_DEPS="exiftool"
MD_PRIORITY=20
MD_PRODUCES="metadata_value flag"

analyze_metadata() {
    local f="$1"
    header "Metadata" "EXIF & Tags"
    if ! command -v exiftool &>/dev/null; then
        info "exiftool not installed"
        return
    fi
    local et_out=$(run_cmd exiftool "$f")
    [ -z "$et_out" ] && { info "No metadata"; return; }

    while IFS=': ' read -r field value; do
        [ -z "$value" ] && continue
        echo "  $field: $value"
        if echo "$value" | grep -qiE 'flag|ctf|ncse|pico|secret|[a-z]{3,15}\{|[A-Z]{3,10}\{'; then
            emit_finding "metadata_value" "$field: $value"
        fi
        local lines=$(echo "$value" | wc -l 2>/dev/null)
        [ "$lines" -ge 2 ] && {
            local acr=$(echo "$value" | grep -o '^.' | tr -d '\n')
            if [ ${#acr} -ge 3 ]; then
                emit_finding "metadata_value" "Acrostic: $acr"
            fi
        }
    done <<< "$et_out"
}
