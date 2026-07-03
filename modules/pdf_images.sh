MD_NAME="PDF Images"
MD_DESC="Extract embedded images from PDF files using pdfimages"
MD_TYPES="pdf"
MD_DEPS="pdfimages"
MD_PRIORITY=36
MD_PRODUCES="pdf_image flag"

analyze_pdf_images() {
    local f="$1"
    header "PDF Images" "Embedded Image Extraction"

    local img_dir="$OUTDIR/pdf_images"
    mkdir -p "$img_dir"
    local prefix="$img_dir/$(basename "$f" .pdf)_page"

    pdfimages -all "$f" "$prefix" 2>/dev/null

    local found=0
    for img in "$img_dir"/*.jpg "$img_dir"/*.png "$img_dir"/*.ppm "$img_dir"/*.tif; do
        [ -f "$img" ] || continue
        found=1
        info "Extracted image: $img"
        emit "pdf_image" "PDF embedded image: $img"
        run_workflow "$img"
    done

    [ "$found" -eq 0 ] && return
}
