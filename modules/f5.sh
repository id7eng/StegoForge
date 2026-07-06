MD_NAME="F5"
MD_DESC="Extract data from F5-embedded JPEGs using multiple methods"
MD_TYPES="jpg jpeg"
MD_DEPS="python3"
MD_PRIORITY=44
MD_PRODUCES="f5_data flag"
MD_TRIGGERS="steg_tool"

F5_JAR="${TOOL_DIR}/lib/f5.jar"
F5_JAR_URLS=(
    "https://github.com/compromyse/f5-steganography/releases/download/v1.0/f5.jar"
    "https://github.com/m4n1k/StegCracker/raw/master/f5.jar"
)

analyze_f5() {
    local f="$1" wl="$2"
    header "F5" "JPEG DCT Steganography Extraction"

    local detected=false
    for ev in "${EMITTED[@]}"; do
        echo "$ev" | grep -qi "f5" && detected=true
    done
    $detected && info "F5 detected by StegDetect"

    local found_any=false

    # ─── Method 1: f5 Java CLI ───
    if command -v java &>/dev/null && [ -z "${STEGOFORGE_TEST:-}" ]; then
        if [ ! -f "$F5_JAR" ] || [ "$(stat -c%s "$F5_JAR" 2>/dev/null)" -lt 1000 ]; then
            mkdir -p "$(dirname "$F5_JAR")"
            info "Downloading f5.jar..."
            for url in "${F5_JAR_URLS[@]}"; do
                log_cmd_str "curl -sL \"$url\" -o \"$F5_JAR\""
                curl -sL "$url" -o "$F5_JAR" 2>/dev/null
                [ -f "$F5_JAR" ] && [ -s "$F5_JAR" ] && { info "f5.jar ready"; break; }
            done
        fi
        if [ -f "$F5_JAR" ]; then
            local outfile="${OUTDIR}/carved/f5_out"
            info "Extracting with f5.jar..."
            for pw in "" "secret" "password" "flag" "ctf" "stego" "hidden" "key"; do
                run_cmd java -jar "$F5_JAR" extract "$f" -p "$pw" -o "$outfile"
                if [ -f "$outfile" ] && [ -s "$outfile" ]; then
                    local data=$(run_cmd strings "$outfile")
                    [ -n "$data" ] && echo "  [$pw] → $data"
                    local flag=$(extract_flags "$data" | head -1)
                    [ -n "$flag" ] && emit "flag" "FLAG: $flag (f5)" && found_any=true
                    rm -f "$outfile"
                    if $found_any; then return; fi
                fi
            done
            # Wordlist passwords
            if [ -f "$wl" ]; then
                while IFS= read -r pw; do
                    [ -z "$pw" ] && continue
                    run_cmd java -jar "$F5_JAR" extract "$f" -p "$pw" -o "$outfile"
                    if [ -f "$outfile" ] && [ -s "$outfile" ]; then
                        local data=$(run_cmd strings "$outfile")
                        [ -n "$data" ] && echo "  [$pw] → $data"
                        local flag=$(extract_flags "$data" | head -1)
                        [ -n "$flag" ] && emit "flag" "FLAG: $flag (f5:$pw)" && found_any=true
                        rm -f "$outfile"
                        break
                    fi
                done < "$wl"
            fi
            if $found_any; then return; fi
        fi
    fi

    # ─── Method 2: Python DCT analysis ───
    info "Trying Python DCT extraction..."
    log_cmd_str "python3 -c '...' (f5 DCT analysis on $f) 2>/dev/null | while ..."
    python3 -c "
import sys, os, hashlib, struct

# Try to extract DCT coefficients using available libraries
dct_coeffs = []

# Method 2a: Try jpeglib (libjpeg-turbo bindings)
try:
    import jpeglib
    im = jpeglib.read_dct('$f')
    for comp in im.blocks:
        for block in comp:
            for coeff in block.flatten():
                dct_coeffs.append(coeff)
except ImportError:
    pass

# Method 2b: Try PIL + scipy DCT on pixel blocks
if not dct_coeffs:
    try:
        from PIL import Image
        import numpy as np
        from scipy.fftpack import dct
        img = Image.open('$f').convert('L')
        arr = np.array(img, dtype=float)
        h, w = arr.shape
        for y in range(0, h - 7, 8):
            for x in range(0, w - 7, 8):
                block = arr[y:y+8, x:x+8]
                # Apply 2D DCT
                dct_block = dct(dct(block, axis=0), axis=1)
                # Quantization (approximate with standard JPEG matrix)
                q = np.array([
                    [16,11,10,16,24,40,51,61],
                    [12,12,14,19,26,58,60,55],
                    [14,13,16,24,40,57,69,56],
                    [14,17,22,29,51,87,80,62],
                    [18,22,37,56,68,109,103,77],
                    [24,35,55,64,81,104,113,92],
                    [49,64,78,87,103,121,120,101],
                    [72,92,95,98,112,100,103,99]
                ], dtype=float)
                quantized = np.round(dct_block / q)
                for coeff in quantized.flatten():
                    dct_coeffs.append(int(coeff))
    except ImportError:
        pass

if not dct_coeffs:
    print('ERR:Could not extract DCT coefficients (install jpeglib or scipy)')
    sys.exit(0)

# F5 extraction: read LSB from non-zero AC coefficients
# Skip DC coefficient (first of each 64-block)
ac = [abs(c) & 1 for c in dct_coeffs if c != 0]
# Try first 4096 bits
bits = ac[:4096]
chars = []
for i in range(0, len(bits) - 7, 8):
    byte = 0
    for j in range(8):
        byte = (byte << 1) | bits[i + j]
    chars.append(chr(byte))
text = ''.join(chars)
printable = ''.join(c if c.isprintable() or c in '\n\r\t' else '.' for c in text)
if len(printable) > 20 and any(c.isalpha() for c in printable[:30]):
    print(f'TEXT:{printable[:500]}')
print('DONE')
" 2>/dev/null | while IFS= read -r line; do
        case "$line" in
            TEXT:*)
                local text="${line#TEXT:}"
                local flag=$(extract_flags "$text" | head -1)
                [ -n "$flag" ] && emit "flag" "FLAG: $flag (f5_dct)" && found_any=true && echo "    → $flag"
                echo "  $text"
                ;;
            ERR:*)
                info "${line#ERR:}"
                ;;
        esac
    done

    if ! $found_any; then
        info "No F5 data found"
    fi
}
