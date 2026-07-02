MD_NAME="F5"
MD_DESC="Extract data from F5-embedded JPEGs"
MD_TYPES="jpg jpeg"
MD_DEPS="f5"
MD_PRIORITY=44
MD_PRODUCES="f5_data flag"

analyze_f5() {
    local f="$1"
    header "F5" "Data extraction"

    local outfile="${OUTDIR}/carved/f5_out"
    if f5 -e "$f" -o "$outfile" 2>/dev/null; then
        [ -f "$outfile" ] && {
            local content=$(strings "$outfile" 2>/dev/null)
            [ -n "$content" ] && emit "f5_data" "F5 data: $content"
            rm -f "$outfile" 2>/dev/null
        }
    fi
}
