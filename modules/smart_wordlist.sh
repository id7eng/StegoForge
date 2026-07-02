MD_NAME="Smart Wordlist"
MD_DESC="Generate dynamic wordlist from file metadata, strings, and filename"
MD_TYPES="*"
MD_DEPS=""
MD_PRIORITY=5
MD_PRODUCES="smart_wordlist"

analyze_smart_wordlist() {
    local f="$1"
    header "Smart Wordlist" "Dynamic Password Generator"

    local wl_out="${OUTDIR}/.smart_wordlist"
    : > "$wl_out"

    basename "$f" | sed 's/\.[^.]*$//' >> "$wl_out"
    basename "$f" >> "$wl_out"

    strings "$f" 2>/dev/null | grep -oE '[A-Za-z0-9_!@#$%^&*]{4,}' | sort -u >> "$wl_out" 2>/dev/null

    strings "$f" 2>/dev/null | grep -oiE '(password|pass|key|secret) *[:=]? *[A-Za-z0-9_!@#$%^&*]{4,}' | sed 's/.*[:=] *//i' >> "$wl_out" 2>/dev/null

    if command -v exiftool &>/dev/null; then
        exiftool "$f" 2>/dev/null | grep -oE ': .{3,}' | sed 's/^: *//' | grep -oE '[A-Za-z0-9_]{4,}' >> "$wl_out" 2>/dev/null
    fi

    if command -v exif &>/dev/null; then
        exif "$f" 2>/dev/null | grep -oE '[A-Za-z0-9_]{4,}' >> "$wl_out" 2>/dev/null
    fi

    local count=$(sort -u "$wl_out" 2>/dev/null | wc -l)
    [ "$count" -gt 1 ] && {
        sort -u "$wl_out" -o "$wl_out"
        SMART_WL="$wl_out"
        info "Generated $count smart passwords"
    } || {
        rm -f "$wl_out" 2>/dev/null
        SMART_WL=""
    }
}
