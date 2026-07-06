MD_NAME="Cross-LSB"
MD_DESC="Cross-channel multi-bit LSB extraction for PNG/BMP"
MD_TYPES="png bmp"
MD_DEPS="python3"
MD_PRIORITY=35
MD_PRODUCES="lsb_data flag"

analyze_cross_lsb() {
    local f="$1"
    header "Cross-LSB" "Cross-Channel Multi-Bit LSB"

    if ! command -v python3 &>/dev/null; then
        info "python3 not installed"
        return
    fi

    python3 -c "
import sys
try:
    from PIL import Image
except ImportError:
    print('PIL not available')
    sys.exit(1)

img = Image.open('$f').convert('RGB')
pixels = list(img.getdata())

combinations = [
    (0, 1, 2, 'R0 G1 B2'),
    (1, 2, 3, 'R1 G2 B3'),
    (2, 3, 4, 'R2 G3 B4'),
    (0, 0, 0, 'R0 G0 B0'),
    (7, 7, 7, 'MSB all'),
    (0, 1, 1, 'R0 G1 B1'),
    (1, 0, 2, 'R1 G0 B2'),
]

for r_bit, g_bit, b_bit, label in combinations:
    bits = []
    for r, g, b in pixels:
        bits.append(str((r >> r_bit) & 1))
        bits.append(str((g >> g_bit) & 1))
        bits.append(str((b >> b_bit) & 1))

    raw_bytes = bytearray()
    for i in range(0, len(bits) - 7, 8):
        byte = 0
        for j in range(8):
            byte = (byte << 1) | int(bits[i + j])
        raw_bytes.append(byte)

    text = bytes(raw_bytes).decode('utf-8', errors='replace')
    text = ''.join(c if c.isprintable() or c in '\n\r\t' else '.' for c in text)

    print(f'--- [{label}] ---')
    print(text[:4096])
" 2>/dev/null | while IFS= read -r line; do
        case "$line" in
            ---\ *---)
                local label="${line#--- }"; label="${label% ---}"
                echo "  [$label]"
                ;;
            PIL*|Error*)
                info "$line"
                ;;
            "")
                ;;
            *)
                local flag=$(extract_flags "$line" | head -1)
                if [ -n "$flag" ]; then
                    emit "flag" "FLAG: $flag (cross_lsb)"
                    echo "    → $flag"
                fi
                local b64=$(echo "$line" | grep -oE '[A-Za-z0-9+/]{30,}={0,2}' | head -1)
                if [ -n "$b64" ]; then
                    local d=$(echo "$b64" | base64 -d 2>/dev/null)
                    if [ -n "$d" ] && echo "$d" | grep -qiE "flag|ctf|ncse|pico|secret" 2>/dev/null; then
                        emit "flag" "FLAG: $d (cross_lsb)"
                        echo "    → $d (base64 decoded)"
                    fi
                fi
                echo "    $line"
                ;;
        esac
    done
}
