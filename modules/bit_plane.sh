MD_NAME="Bit Plane"
MD_DESC="Extract LSB bit planes as images"
MD_TYPES="png bmp"
MD_DEPS="python3-pil"
MD_PRIORITY=45
MD_PRODUCES="bitplane"

analyze_bit_plane() {
    local f="$1"
    header "Bit Plane" "LSB Bit Plane Extraction"
    local bpd="${OUTDIR}/bitplanes/$(basename "$f")"
    mkdir -p "$bpd"

    python3 -c "
from PIL import Image
import os, sys

img = Image.open('$f')
if img.mode == 'RGBA':
    bands = 4
elif img.mode == 'RGB':
    bands = 3
elif img.mode == 'L':
    bands = 1
elif img.mode == 'P':
    img = img.convert('RGB')
    bands = 3
else:
    print(f'ERR:unsupported mode {img.mode}')
    sys.exit(0)

w, h = img.size
pixels = list(img.getdata())
outdir = '$bpd'

for bi in range(8):
    plane = Image.new('L', (w, h))
    pdata = []
    for px in pixels:
        if bands == 1:
            val = (px if isinstance(px, int) else px[0]) >> bi & 1
        else:
            total = 0
            for j in range(min(bands, 4)):
                total += (px[j] >> bi & 1) if isinstance(px, (tuple, list)) else (px >> bi & 1)
            val = total // min(bands, 4)
        pdata.append(val * 255)
    plane.putdata(pdata)
    plane.save(os.path.join(outdir, f'bit{bi}.png'))

print(f'OK:{w}x{h}')
" 2>/dev/null | while read line; do
        case "$line" in
            OK:*) emit "bitplane" "8 bit planes → $bpd/" ;;
            ERR:*) info "${line#ERR:}" ;;
        esac
    done
}
