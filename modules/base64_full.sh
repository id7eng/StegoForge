MD_NAME="Base64 Full"
MD_DESC="Detect & decode full-file base64 → reconstruct original format"
MD_TYPES="txt text"
MD_DEPS="base64 file"
MD_PRIORITY=8
MD_PRODUCES="reconstructed"

analyze_base64_full() {
    local f="$1"
    header "Base64 Full" "Full-File Base64 Decode → Reconstruction"

    # Check if file is mostly base64 (skip short files)
    local size=$(stat -c%s "$f" 2>/dev/null)
    [ "$size" -lt 100 ] && return

    # Sample first 1KB after stripping whitespace
    local sample=$(head -c 1024 "$f" 2>/dev/null | tr -d '[:space:]')
    local alnum=$(echo "$sample" | tr -dc 'A-Za-z0-9+/=' | wc -c)
    local total=$(echo "$sample" | wc -c)

    # Must be at least 90% base64 chars
    [ "$total" -gt 0 ] || return
    local pct=$((alnum * 100 / total))
    [ "$pct" -lt 90 ] && return

    # Try decoding the entire file
    local data=$(tr -d '[:space:]' < "$f" 2>/dev/null)
    local outfile="${OUTDIR}/carved/base64_decoded.bin"

    echo "$data" | run_cmd base64 -d > "$outfile"
    if [ -f "$outfile" ] && [ -s "$outfile" ]; then
        local outsize=$(stat -c%s "$outfile")
        info "Decoded $size bytes → $outsize bytes ($outfile)"
        # Check magic bytes
        local magic=$(xxd -l 4 -p "$outfile" 2>/dev/null)
        local detected=""
        case "$magic" in
            89504e47) detected="PNG image" ;;
            ffd8ffe0|ffd8ffe1|ffd8ffdb) detected="JPEG image" ;;
            47494638) detected="GIF image" ;;
            504b0304) detected="ZIP archive" ;;
            25504446) detected="PDF document" ;;
            424d) detected="BMP image" ;;
        esac
        [ -n "$detected" ] && emit_finding "reconstructed" "Base64 → $detected ($outfile)" || emit_finding "reconstructed" "Base64 → unknown format ($outfile)"
        run_workflow "$outfile"
    else
        info "Base64 decode produced no output (empty or invalid)"
    fi
}
