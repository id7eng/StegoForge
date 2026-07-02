MD_NAME="Zero Width"
MD_DESC="Detect and decode zero-width character steganography"
MD_TYPES="txt text html css js"
MD_DEPS="python3"
MD_PRIORITY=33
MD_PRODUCES="zw_data flag"

analyze_zero_width() {
    local f="$1"
    header "Zero-Width" "Invisible Characters"

    local out=$(python3 -c "
import sys
with open('$f', 'r', errors='replace') as f:
    content = f.read()

zw = {'\u200b': '0', '\u200c': '0', '\u200d': '1', '\ufeff': '1',
      '\u2060': '0', '\u2061': '1', '\u2062': '0', '\u2063': '1',
      '\u2064': '0', '\u2066': '1', '\u2067': '0', '\u2068': '1',
      '\u2069': '0', '\u202a': '1', '\u202b': '0', '\u202c': '1',
      '\u202d': '0', '\u202e': '1'}

bits = ''
for c in content:
    if c in zw:
        bits += zw[c]

if len(bits) < 8:
    sys.exit(0)

chars = ''
for i in range(0, len(bits) - len(bits) % 8, 8):
    b = bits[i:i+8]
    if b == '00000000':
        break
    chars += chr(int(b, 2))

if chars.strip():
    print(chars)
" 2>/dev/null)

    [ -n "$out" ] && emit "zw_data" "Zero-width decoded: $out"
}
