MD_NAME="SSTV"
MD_DESC="Decode SSTV (Slow Scan Television) images from WAV audio"
MD_TYPES="wav"
MD_DEPS="sstv"
MD_PRIORITY=52
MD_PRODUCES="sstv_image flag"

analyze_sstv() {
    local f="$1"
    header "SSTV" "SSTV Image Decode"

    local outfile="${OUTDIR}/carved/sstv_out.png"
    if command -v sstv &>/dev/null; then
        sstv -d "$f" -o "$outfile" 2>/dev/null && {
            [ -f "$outfile" ] && {
                info "SSTV image → $outfile"
                $VERBOSE && echo "  [*] SSTV decoded: $outfile"
            }
        }
    elif command -v qsstv &>/dev/null; then
        qsstv --decode "$f" --output "$outfile" 2>/dev/null && {
            [ -f "$outfile" ] && {
                info "SSTV image → $outfile"
            }
        }
    else
        info "SSTV tools not available"
    fi
}
