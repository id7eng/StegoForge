MD_NAME="Foremost"
MD_DESC="File carving"
MD_TYPES="*"
MD_DEPS="foremost"
MD_PRIORITY=70
MD_PRODUCES="carved_file"

analyze_foremost() {
    local f="$1"
    header "Foremost" "File Carving"
    if command -v foremost &>/dev/null; then
        local d="${OUTDIR}/carved/foremost"
        foremost -o "$d" "$f" >/dev/null 2>&1
        local n=$(find "$d" -type f 2>/dev/null | wc -l)
        [ "$n" -gt 1 ] && emit "carved_file" "$((n-1)) files carved" || info "Nothing extra found"
    else info "foremost not installed"; fi
}
