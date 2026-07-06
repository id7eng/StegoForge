MD_NAME="StegSeek"
MD_DESC="Fast steghide password cracker (wordlist)"
MD_TYPES="jpg jpeg bmp wav"
MD_DEPS="stegseek"
MD_PRIORITY=39
MD_PRODUCES="password steghide_data"

analyze_stegseek() {
    local f="$1" wl="$2"
    header "StegSeek" "Fast Steghide Brute-Force"
    [ -z "$wl" ] || [ ! -f "$wl" ] && wl="$SMART_WL"
    [ -z "$wl" ] || [ ! -f "$wl" ] && { info "No wordlist provided"; return; }

    info "Cracking with stegseek..."
    local outfile="${OUTDIR}/carved/stegseek_out"
    run_cmd stegseek "$f" "$wl" -o "$outfile" --quiet
    [ -f "$outfile" ] && {
        local pass=$(stegseek "$f" "$wl" 2>&1 | grep -oP 'password: \K.*' | head -1)
        [ -n "$pass" ] && emit "password" "StegSeek password: $pass"
        local content=$(strings "$outfile" 2>/dev/null | head -10)
        [ -n "$content" ] && emit "steghide_data" "$content"
        rm -f "$outfile" 2>/dev/null
    }
}
