MD_NAME="ADS Scan"
MD_DESC="NTFS Alternate Data Stream detection"
MD_TYPES="*"
MD_DEPS="getfattr"
MD_PRIORITY=90
MD_PRODUCES="ads_found"

analyze_ads_scan() {
    local f="$1"
    header "ADS Scan" "NTFS Alternate Data Streams"

    if ! command -v getfattr &>/dev/null; then
        info "getfattr not available"
        return
    fi

    local target="$f"
    [ -d "$f" ] && target="$f" || target="$(dirname "$f")"

    if mount 2>/dev/null | grep -q "$target" && mount 2>/dev/null | grep "$target" | grep -qi 'ntfs'; then
        find "$target" -type f 2>/dev/null | while read file; do
            local streams=$(getfattr -d "$file" 2>/dev/null | grep ':' | cut -d= -f1)
            [ -z "$streams" ] && continue
            warn "ADS on $file"
            for s in $streams; do
                local content=$(cat "$file:$s" 2>/dev/null | strings | tr '\n' ' ')
                emit "ads_found" "ADS: $file:$s"
                [ -n "$content" ] && emit "ads_found" "ADS content: $content"
            done
        done
    else
        info "Not on NTFS"
    fi
}
