MD_NAME="OCR"
MD_DESC="Extract text from images using Tesseract OCR (screenshots, photos)"
MD_TYPES="jpg jpeg png bmp gif tiff"
MD_DEPS="tesseract"
MD_PRIORITY=22
MD_PRODUCES="ocr_text flag"

analyze_ocr() {
    local f="$1"
    header "OCR" "Image Text Recognition"
    if ! command -v tesseract &>/dev/null; then
        info "tesseract-ocr not installed"
        return
    fi

    local tmpimg=$(mktemp /tmp/stegoforge_ocr_XXXXX.png)
    export OCR_FILE="$f"
    export OCR_TMPIMG="$tmpimg"
    python3 -c "
import os
from PIL import Image
img = Image.open(os.environ['OCR_FILE']).convert('RGBA')
# Make transparent pixels white
pixels = []
for p in img.getdata():
    if p[3] < 128:
        pixels.append((255, 255, 255, 255))
    else:
        pixels.append(p)
img.putdata(pixels)
# Scale if too small
w, h = img.size
if w < 200 or h < 200:
    scale = max(4, 200 // w, 200 // h)
    img = img.resize((w * scale, h * scale), Image.NEAREST)
img = img.convert('L')
img.save(os.environ['OCR_TMPIMG'])
" 2>/dev/null
    unset OCR_FILE OCR_TMPIMG

    local out=$(tesseract "$tmpimg" stdout -l eng 2>/dev/null | tr -d '\0' | grep -v '^$')
    rm -f "$tmpimg"
    [ -z "$out" ] && { info "No text found"; return; }

    while IFS= read -r line; do
        [ -n "$line" ] && emit "ocr_text" "OCR: $line"
    done <<< "$out"

    local combined=""
    for p in "${FLAG_PATTERNS[@]}"; do
        [ -n "$combined" ] && combined+="|"
        combined+="$p"
    done
    [ -n "$combined" ] && while IFS= read -r m; do
        [ -n "$m" ] && emit "flag" "$m"
    done < <(echo "$out" | grep -oP "$combined" 2>/dev/null)

    # Partial / tail flag matching from OCR output
    while IFS= read -r partial; do
        [ -n "$partial" ] && emit "partial_flag" "OCR: $partial"
    done < <(echo "$out" | grep -oP '[a-zA-Z0-9_!@#$%^&*()+\-]{6,}\}' 2>/dev/null)
}
