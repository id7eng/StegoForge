MD_NAME="OutGuess"
MD_DESC="Extract data from outguess-embedded JPEGs"
MD_TYPES="jpg jpeg"
MD_DEPS="outguess"
MD_PRIORITY=42
MD_PRODUCES="outguess_data flag"

analyze_outguess() {
    local f="$1"
    header "OutGuess" "Data extraction"

    local outfile="${OUTDIR}/carved/outguess_out"
    if run_cmd outguess -r "$f" "$outfile"; then
        [ -f "$outfile" ] && {
            local content=$(strings "$outfile" 2>/dev/null)
            [ -n "$content" ] && emit "outguess_data" "OutGuess data: $content"
            rm -f "$outfile" 2>/dev/null
        }
    fi
    # Try with empty password
    if run_cmd outguess -k "" -r "$f" "${outfile}_2"; then
        [ -f "${outfile}_2" ] && {
            local content=$(strings "${outfile}_2" 2>/dev/null)
            [ -n "$content" ] && emit "outguess_data" "OutGuess (empty pass): $content"
            rm -f "${outfile}_2" 2>/dev/null
        }
    fi
}
