MD_NAME="GIF Palette"
MD_DESC="Analyze local palettes in GIF frames for hidden data"
MD_TYPES="gif"
MD_DEPS="python3"
MD_PRIORITY=37
MD_PRODUCES="gif_palette flag"

analyze_gif_palette() {
    local f="$1"
    header "GIF Palette" "Local Frame Palette Analysis"

    export GIFPALETTE_FILE="$f"
    python3 -c "
import os, sys
from PIL import Image

try:
    img = Image.open(os.environ['GIFPALETTE_FILE'])
except Exception:
    sys.exit(0)

frame = 0
while True:
    try:
        img.seek(frame)
    except EOFError:
        break

    palette = img.getpalette()
    if palette:
        # Extract LSB from palette entries
        bits = ''.join(str(p & 1) for p in palette[:256*3])
        chars = ''
        for i in range(0, len(bits) - len(bits) % 8, 8):
            b = bits[i:i+8]
            c = int(b, 2)
            if 32 <= c <= 126:
                chars += chr(c)
        if len(chars) > 3:
            print(f'Frame {frame}: {chars}')

        # Check for ASCII in palette description
        desc = ''.join(chr(p) if 32 <= p <= 126 else '' for p in palette[:256*3])
        texts = []
        import re
        for m in re.finditer(r'[A-Za-z0-9_{}]{4,}', desc):
            texts.append(m.group())
        if texts:
            print(f'Frame {frame} text: {\" | \".join(texts)}')
    frame += 1
" 2>/dev/null)
    while read line; do
        emit "gif_palette" "$line"
    done < <(python3 -c "
import os, sys
from PIL import Image

try:
    img = Image.open(os.environ['GIFPALETTE_FILE'])
except Exception:
    sys.exit(0)

frame = 0
while True:
    try:
        img.seek(frame)
    except EOFError:
        break

    palette = img.getpalette()
    if palette:
        # Extract LSB from palette entries
        bits = ''.join(str(p & 1) for p in palette[:256*3])
        chars = ''
        for i in range(0, len(bits) - len(bits) % 8, 8):
            b = bits[i:i+8]
            c = int(b, 2)
            if 32 <= c <= 126:
                chars += chr(c)
        if len(chars) > 3:
            print(f'Frame {frame}: {chars}')

        # Check for ASCII in palette description
        desc = ''.join(chr(p) if 32 <= p <= 126 else '' for p in palette[:256*3])
        texts = []
        import re
        for m in re.finditer(r'[A-Za-z0-9_{}]{4,}', desc):
            texts.append(m.group())
        if texts:
            print(f'Frame {frame} text: {\" | \".join(texts)}')
    frame += 1
" 2>/dev/null)
    unset GIFPALETTE_FILE
}
