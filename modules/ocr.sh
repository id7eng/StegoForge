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

    local out=$(tesseract "$f" stdout -l eng 2>/dev/null | tr -d '\0' | grep -v "^$")
    [ -z "$out" ] && { info "No text found"; return; }

    while read line; do
        [ -n "$line" ] && emit "ocr_text" "OCR: $line"
    done <<< "$out"
}
