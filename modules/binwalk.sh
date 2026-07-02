MD_NAME="Binwalk"
MD_DESC="Detect embedded/carved files"
MD_TYPES="*"
MD_DEPS="binwalk"
MD_PRIORITY=60
MD_PRODUCES="embedded_file"

analyze_binwalk() {
    local f="$1"
    header "Binwalk" "Embedded Files"
    if command -v binwalk &>/dev/null; then
        local bw=$(binwalk "$f" 2>/dev/null | grep -v '^$\|Scan Time\|Target\|MD5\|Signatures\|DECIMAL')
        [ -n "$bw" ] && echo "$bw" && emit "embedded_file" "Embedded files detected"
        binwalk -Me "$f" -C "${OUTDIR}/carved" >/dev/null 2>&1
        local d="${OUTDIR}/carved/_$(basename "$f").extracted"
        [ -d "$d" ] && info "$(find "$d" -type f 2>/dev/null | wc -l) extracted"
    else info "binwalk not installed"; fi
}
