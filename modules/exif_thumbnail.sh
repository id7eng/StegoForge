MD_NAME="EXIF Thumbnail"
MD_DESC="Extract and analyze embedded EXIF thumbnail images"
MD_TYPES="jpg jpeg"
MD_DEPS="exiftool"
MD_PRIORITY=16
MD_PRODUCES="thumbnail flag"

analyze_exif_thumbnail() {
    local f="$1"
    header "EXIF Thumbnail" "Thumbnail Image Extraction"

    local thumb_size=$(exiftool -b -ThumbnailImage "$f" 2>/dev/null | wc -c)
    [ "$thumb_size" -eq 0 ] && return

    local thumb_dir="$OUTDIR/thumbnails"
    mkdir -p "$thumb_dir"
    local thumb_file="$thumb_dir/$(basename "$f")_thumb.jpg"
    run_cmd exiftool -b -ThumbnailImage "$f" > "$thumb_file"

    if [ -f "$thumb_file" ] && [ -s "$thumb_file" ]; then
        info "Extracted $thumb_size-byte thumbnail: $thumb_file"
        emit "thumbnail" "EXIF thumbnail extracted: $thumb_file"
        run_workflow "$thumb_file"
    fi
}
