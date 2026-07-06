MD_NAME="Binwalk"
MD_DESC="Detect embedded/carved files"
MD_TYPES="*"
MD_DEPS="binwalk"
MD_PRIORITY=60
MD_PRODUCES="embedded_file"

analyze_binwalk() {
    local f="$1"
    if [[ -n "$FIXED_FILE_PATH" ]] && [[ "$f" == "$FIXED_FILE_PATH" ]]; then
        $QUIET || header "Binwalk" "Embedded Files"
        $QUIET || info "Skipped — file was fixed by Polyglot Fixer"
        return 0
    fi
    header "Binwalk" "Embedded Files"
    if command -v binwalk &>/dev/null; then
        local bw=$(binwalk "$f" 2>/dev/null | grep -v '^$\|Scan Time\|Target\|MD5\|Signatures\|DECIMAL')
        [ -n "$bw" ] && emit "embedded_file" "Embedded files detected"
        run_cmd binwalk -Me "$f" -C "${OUTDIR}/carved" >/dev/null 2>&1
        local d="${OUTDIR}/carved/_$(basename "$f").extracted"
        [ -d "$d" ] && $QUIET || info "$(find "$d" -type f 2>/dev/null | wc -l) extracted"
    else info "binwalk not installed"; fi
}
