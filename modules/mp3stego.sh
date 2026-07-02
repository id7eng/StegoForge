MD_NAME="MP3Stego"
MD_DESC="Extract hidden data from MP3 files"
MD_TYPES="mp3"
MD_DEPS="MP3Stego"
MD_PRIORITY=48
MD_PRODUCES="mp3stego_data flag"

analyze_mp3stego() {
    local f="$1"
    header "MP3Stego" "Data extraction"

    local outfile="${OUTDIR}/carved/mp3stego_out"
    MP3Stego -X -p "" "$f" -o "$outfile" 2>/dev/null
    [ -f "$outfile" ] && {
        local content=$(strings "$outfile" 2>/dev/null)
        [ -n "$content" ] && emit "mp3stego_data" "MP3Stego data: $content"
        rm -f "$outfile" 2>/dev/null
    }
}
