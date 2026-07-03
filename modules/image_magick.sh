MD_NAME="ImageMagick"
MD_DESC="Image analysis + manipulation via ImageMagick (identify/compare)"
MD_TYPES="jpg jpeg png bmp gif tiff webp"
MD_DEPS="file"
MD_PRIORITY=14
MD_PRODUCES="image_info"

analyze_image_magick() {
    local f="$1"
    header "ImageMagick" "Image Properties & Manipulation"

    if ! command -v identify &>/dev/null; then
        info "identify (ImageMagick) not installed"
        return
    fi

    local info=$(identify -verbose "$f" 2>/dev/null)
    [ -z "$info" ] && { info "identify failed"; return; }

    local dims=$(echo "$info" | grep -i 'Geometry:\|Page:' | head -1)
    [ -n "$dims" ] && emit "image_info" "Dimensions: ${dims##* }"

    local depth=$(echo "$info" | grep -i 'Depth:' | head -1)
    [ -n "$depth" ] && emit "image_info" "${depth##* }"

    local colorspace=$(echo "$info" | grep -i 'Colorspace:' | head -1)
    [ -n "$colorspace" ] && emit "image_info" "${colorspace##* }"

    local compression=$(echo "$info" | grep -i 'Compression:' | head -1)
    [ -n "$compression" ] && emit "image_info" "${compression##* }"

    local channel_stats=$(echo "$info" | grep -A5 'Channel statistics:' 2>/dev/null)
    if [ -n "$channel_stats" ]; then
        while IFS= read -r line; do
            emit "image_info" "Channel: $line"
        done < <(echo "$channel_stats" | grep -v 'Channel statistics:' | grep -v '^--$')
    fi

    echo "$info" | grep -qiE 'profile|comment|label|caption|description' && \
        emit "image_info" "Embedded metadata/profiles detected"
}
