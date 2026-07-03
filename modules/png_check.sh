MD_NAME="PNG Check"
MD_DESC="Validate PNG structure, detect anomalous chunks (pngcheck)"
MD_TYPES="png"
MD_DEPS="pngcheck"
MD_PRIORITY=23
MD_PRODUCES="png_anomaly"

analyze_png_check() {
    local f="$1"
    header "PNG Check" "Chunk-level Structure Analysis"

    local out=$(pngcheck -v "$f" 2>/dev/null)
    if [ -z "$out" ]; then
        info "pngcheck failed"
        return
    fi

    while IFS= read -r line; do
        emit "png_data" "PNG: $line"
    done < <(echo "$out")

    local anomalies=$(echo "$out" | grep -iE 'unknown|invalid|extra|suspicious|anomal|corrupt|unexpected|private' 2>/dev/null)
    if [ -n "$anomalies" ]; then
        while IFS= read -r line; do
            emit "png_anomaly" "Anomalous chunk: $line"
        done <<< "$anomalies"
    fi

    local chunk_count=$(echo "$out" | grep -cE '^  [A-Z]' 2>/dev/null)
    [ "$chunk_count" -gt 0 ] && emit "png_data" "Total chunks: $chunk_count"

    if echo "$out" | grep -qiE 'extra|trailing|after IEND|data after'; then
        emit "png_anomaly" "Trailing data detected after IEND"
    fi

    if echo "$out" | grep -qiE 'private|unknown chunk'; then
        emit "png_anomaly" "Private/unknown chunk found — possible stego data"
    fi
}
