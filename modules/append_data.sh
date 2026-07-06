MD_NAME="Append Data"
MD_DESC="Detect & extract data appended after PNG IEND / JPEG EOI markers"
MD_TYPES="*"
MD_DEPS="python3"
MD_PRIORITY=28
MD_PRODUCES="appended_flag"

analyze_append_data() {
    local f="$1"
    header "Append Data" "Data After End Marker Detection"

export APPEND_DATA_FILE="$f"
local results=$(run_cmd python3 -c "
import os, struct, sys

with open(os.environ['APPEND_DATA_FILE'], 'rb') as f:
    data = f.read()

# Check PNG IEND
if data[:8] == b'\x89PNG\r\n\x1a\n':
    pos = 8
    while pos + 8 <= len(data):
        length = struct.unpack('>I', data[pos:pos+4])[0]
        chunk_type = data[pos+4:pos+8]
        if chunk_type == b'IEND':
            after = pos + 12
            if after < len(data):
                print(f'PNG_IEND:{after}:{len(data)-after}')
            break
        pos += 12 + length

# Check JPEG EOI
if data[:2] == b'\xff\xd8':
    eoi = data.find(b'\xff\xd9')
    if eoi != -1 and eoi + 2 < len(data):
        after = eoi + 2
        if after < len(data):
            print(f'JPEG_EOI:{after}:{len(data)-after}')
")
unset APPEND_DATA_FILE

while IFS= read -r result; do
    [ -z "$result" ] && continue
    local marker="${result%%:*}"
    local rest="${result#*:}"
    local offset="${rest%%:*}"
    local extra_len="${rest##*:}"
    info "Found $extra_len bytes after $marker marker (offset $offset)"

    local outfile="${OUTDIR}/carved/after_${marker}_data.bin"
    run_cmd dd if="$f" bs=1 skip="$offset" > "$outfile"

    if [ -f "$outfile" ] && [ -s "$outfile" ]; then
        local magic=$(run_cmd xxd -l 4 -p "$outfile")
        local detected=""
        case "$magic" in
            504b0304) detected="ZIP archive" ;;
            25504446) detected="PDF document" ;;
        esac
        if [ -z "$detected" ]; then
            local text_ratio=$(LC_ALL=C strings "$outfile" 2>/dev/null | tr -d '\0' | wc -c)
            local total=$(stat -c%s "$outfile" 2>/dev/null)
            [ "$text_ratio" -gt $((total * 60 / 100)) ] && detected="text data"
        fi

        [ -n "$detected" ] && emit "appended" "Appended $detected ($(stat -c%s "$outfile") bytes)"
        run_workflow "$outfile"
    fi
done < <(echo "$results")
}
