MD_NAME="Binary Digits"
MD_DESC="Detect & convert binary-text files (0s and 1s) to original format"
MD_TYPES="txt text"
MD_DEPS="python3"
MD_PRIORITY=7
MD_PRODUCES="reconstructed"

analyze_binary_digits() {
    local f="$1"
    header "Binary Digits" "Binary Text → File Reconstruction"

    local first=$(head -c 500 "$f" 2>/dev/null | tr -d '[:space:]')
    if ! echo "$first" | grep -qE '^[01]+$'; then
        return
    fi

    local outfile="${OUTDIR}/carved/reconstructed.bin"
    export BINARY_FILE="$f"
    export BINARY_OUTFILE="$outfile"
    while read line; do info "$line"; done < <(python3 -c "
import os, sys
with open(os.environ['BINARY_FILE'], 'r') as f:
    bits = f.read().strip().replace(' ', '').replace('\n', '').replace('\r', '').replace('\t', '')
data = bytes(int(bits[i:i+8], 2) for i in range(0, len(bits) - len(bits) % 8, 8) if len(bits[i:i+8]) == 8)
with open(os.environ['BINARY_OUTFILE'], 'wb') as f:
    f.write(data)
print(f'Wrote {len(data)} bytes')
" 2>/dev/null)
    unset BINARY_FILE BINARY_OUTFILE

    if [ -f "$outfile" ] && [ -s "$outfile" ]; then
        run_workflow "$outfile"
    fi
}
