MD_NAME="Binary Border"
MD_DESC="Extract data from image border pixels (clockwise)"
MD_TYPES="jpg jpeg png bmp gif"
MD_DEPS="python3"
MD_PRIORITY=47
MD_PRODUCES="border_data flag"

analyze_binary_border() {
    local f="$1"
    header "Binary Border" "Border Pixel Steganography"

    python3 -c "
from PIL import Image
import sys

try:
    img = Image.open('$f').convert('RGB')
    w, h = img.size
    pix = img.load()
except Exception:
    sys.exit(0)

bits = ''
# Top row (L→R)
for x in range(w):
    r, g, b = pix[x, 0]
    bits += '1' if (r + g + b) // 3 > 128 else '0'
# Right col (T→B, exclude corners)
for y in range(1, h - 1):
    r, g, b = pix[w - 1, y]
    bits += '1' if (r + g + b) // 3 > 128 else '0'
# Bottom row (R→L)
for x in range(w - 1, -1, -1):
    r, g, b = pix[x, h - 1]
    bits += '1' if (r + g + b) // 3 > 128 else '0'
# Left col (B→T, exclude corners)
for y in range(h - 2, 0, -1):
    r, g, b = pix[0, y]
    bits += '1' if (r + g + b) // 3 > 128 else '0'

chars = ''
for i in range(0, len(bits) - len(bits) % 8, 8):
    b = bits[i:i+8]
    if b == '00000000':
        break
    c = int(b, 2)
    if 32 <= c <= 126:
        chars += chr(c)

if chars.strip():
    print(chars)
" 2>/dev/null | while read line; do
        emit "border_data" "Border data: $line"
    done
}
