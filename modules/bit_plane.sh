MD_NAME="Bit Plane"
MD_DESC="Extract LSB bit planes as images"
MD_TYPES="png bmp"
MD_DEPS="python3-pil"
MD_PRIORITY=45
MD_PRODUCES="bitplane"

analyze_bit_plane() {
    local f="$1"
    header "Bit Plane" "LSB Bit Plane Extraction"

    local size=$(stat -c%s "$f" 2>/dev/null)
    [ "$size" -gt 500000 ] && info "Skip bit plane: file too large ($size bytes)" && return

    local bpd="${OUTDIR}/bitplanes/$(basename "$f")"
    mkdir -p "$bpd"

export BITPLANE_FILE="$f"
export BITPLANE_OUTDIR="$bpd"
local result=$(python3 -c "
import os, sys
from PIL import Image

img = Image.open(os.environ['BITPLANE_FILE'])
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
outdir = os.environ['BITPLANE_OUTDIR']

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
" 2>/dev/null)
unset BITPLANE_FILE BITPLANE_OUTDIR
case "$result" in
    OK:*) emit "bitplane" "8 bit planes → $bpd/" ;;
    ERR:*) info "${result#ERR:}" ;;
esac
}
