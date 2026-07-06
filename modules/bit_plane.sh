MD_NAME="Bit Plane"
MD_DESC="Extract LSB bit planes with optional color filtering + data extraction"
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

    local cond_enabled="${BP_CONDITION_ENABLED:-0}"
    local target_r="${BP_TARGET_R:-0}"
    local target_g="${BP_TARGET_G:-0}"
    local target_b="${BP_TARGET_B:-0}"
    local tolerance="${BP_TOLERANCE:-30}"

    if [ "$cond_enabled" = "0" ] && [ -n "$CHALLENGE_DIR" ]; then
        cond_enabled=1
        target_r=0; target_g=0; target_b=0; tolerance=30
        info "Auto: filtering pixels near RGB($target_r,$target_g,$target_b) ±$tolerance"
    fi

export BITPLANE_FILE="$f"
export BITPLANE_OUTDIR="$bpd"
export BP_COND="$cond_enabled" BP_TR="$target_r" BP_TG="$target_g" BP_TB="$target_b" BP_TOL="$tolerance"
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
cond = int(os.environ.get('BP_COND', '0'))
tr = int(os.environ.get('BP_TR', '0'))
tg = int(os.environ.get('BP_TG', '0'))
tb = int(os.environ.get('BP_TB', '0'))
tol = int(os.environ.get('BP_TOL', '30'))
tol2 = tol * tol

def is_matching(px):
    if not isinstance(px, (tuple, list)) or len(px) < 3:
        return True
    dr = px[0] - tr
    dg = px[1] - tg
    db = px[2] - tb
    return (dr*dr + dg*dg + db*db) <= tol2

for bi in range(8):
    plane = Image.new('L', (w, h))
    pdata = []
    for px in pixels:
        if cond and not is_matching(px):
            pdata.append(128)
            continue
        if bands == 1:
            v = px if isinstance(px, int) else px[0]
            val = v >> bi & 1
        else:
            total = 0
            for j in range(min(bands, 4)):
                total += (px[j] >> bi & 1) if isinstance(px, (tuple, list)) else (px >> bi & 1)
            val = total // min(bands, 4)
        pdata.append(val * 255)
    plane.putdata(pdata)
    plane.save(os.path.join(outdir, f'bit{bi}.png'))
    if cond:
        plane.save(os.path.join(outdir, f'bit{bi}_cond.png'))

# Sequential bit extraction from filtered pixels (LSB of each channel)
if cond:
    seq_bits = ''
    for px in pixels:
        if not is_matching(px):
            continue
        if isinstance(px, (tuple, list)):
            for j in range(min(bands, 3)):
                seq_bits += str(px[j] & 1)
        else:
            seq_bits += str(px & 1)

    # Try multiple bit orders
    orders = [
        ('R0 G0 B0', 0),
        ('R7 G7 B7', 7),
        ('R0 (LSB)', 0, 0),
    ]

    found_texts = []

    def bits_to_text(bits):
        chars = []
        for i in range(0, len(bits) - 7, 8):
            byte = 0
            for j in range(8):
                byte = (byte << 1) | int(bits[i + j])
            chars.append(chr(byte))
        return ''.join(chars)

    # Sequential interleaved: R0,G0,B0,R0,G0,B0,...
    seq_text = bits_to_text(seq_bits)
    found_texts.append(seq_text)

    # Per-channel: all R bits, all G bits, all B bits
    for ch_idx, ch_name in [(0, 'R'), (1, 'G'), (2, 'B')]:
        ch_bits = seq_bits[ch_idx::3]
        ch_text = bits_to_text(ch_bits)
        found_texts.append(f'[{ch_name}] {ch_text}')

    # Print results for the shell to parse
    for t in found_texts:
        printable = ''.join(c if c.isprintable() or c in '\n\r\t' else '.' for c in t)
        print(f'TEXT:{printable[:500]}')

total_px = w * h
if cond:
    matching = sum(1 for px in pixels if is_matching(px))
    pct = (matching * 100) // total_px if total_px else 0
    print(f'COND:{w}x{h} target=({tr},{tg},{tb}) tol={tol} matching={matching}/{total_px} ({pct}%)')
else:
    print(f'OK:{w}x{h}')
" 2>/dev/null)
unset BITPLANE_FILE BITPLANE_OUTDIR BP_COND BP_TR BP_TG BP_TB BP_TOL

local cond_details=""
while IFS= read -r line; do
    case "$line" in
        TEXT:*)
            local text="${line#TEXT:}"
            local flag=$(extract_flags "$text" | head -1)
            if [ -n "$flag" ]; then
                echo "    → $flag"
                emit "flag" "FLAG: $flag (bit_plane cond)"
            fi
            echo "  $text"
            ;;
        COND:*)
            cond_details="${line#COND:}"
            emit "bitplane" "8 conditional bit planes → $bpd/"
            echo "  [Filter] $cond_details"
            ;;
        OK:*)
            emit "bitplane" "8 bit planes → $bpd/"
            ;;
        ERR:*)
            info "${line#ERR:}"
            ;;
    esac
done <<< "$result"
}
