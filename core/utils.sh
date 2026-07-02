banner() {
    [ "$QUIET" = true ] && return
    echo -e "${C}╔══════════════════════════════════════════════╗${N}"
    echo -e "${C}║        ${W}StegoForge v${VERSION}${C} - CTF Toolkit        ║${N}"
    echo -e "${C}║   ${DIM}Steganography & Forensics Toolkit${C}        ║${N}"
    echo -e "${C}╚══════════════════════════════════════════════╝${N}"
}

usage() {
    echo -e "\n${BOLD}StegoForge v${VERSION}${N} - CTF Steganography & Forensics Toolkit"
    echo ""
    echo -e "${BOLD}Usage:${N}  stegoforge [options] <file|directory>"
    echo ""
    echo -e "${BOLD}Options:${N}"
    echo -e "  -v, --verbose       Show detailed analysis"
    echo -e "  -r, --recursive     Scan directory recursively"
    echo -e "  -o, --output DIR    Output directory"
    echo -e "  -j, --json          JSON output"
    echo -e "  -w, --wordlist FILE  Password list for brute-force"
    echo -e "  -l, --list          List available modules"
    echo -e "     --doctor         Check dependencies"
    echo -e "  -h, --help          Show help"
    echo ""
    echo -e "${BOLD}Examples:${N}"
    echo -e "  stegoforge image.png"
    echo -e "  stegoforge -v image.jpg"
    echo -e "  stegoforge -w rockyou.txt image.jpg"
    echo -e "  stegoforge -r ~/challenges/"
    exit 0
}

get_file_type() {
    local f="$1"
    local raw=$(file -b "$f" 2>/dev/null)
    local lower=$(echo "$raw" | tr '[:upper:]' '[:lower:]')
    [ "$lower" = "data" ] || [ "$lower" = "application/octet-stream" ] && {
        local magic=$(xxd -l 8 -p "$f" 2>/dev/null)
        case "$magic" in
            89504e47*) echo "png image data"; return ;;
            ffd8ffe0*|ffd8ffe1*|ffd8ffe2*|ffd8ffdb*|ffd8ffc0*|ffd8ffc2*|ffd8ffc4*|ffd8ffc8*|ffd8fffe*) echo "jpeg image data"; return ;;
            424d*) echo "bmp image data"; return ;;
            504b0304*) echo "zip archive data"; return ;;
        esac
    }
    echo "$lower"
}

flag_format() {
    local s="$1"
    local patterns=("${!2}")
    local found=""
    for p in "${patterns[@]}"; do
        local match=$(echo "$s" | grep -oP "$p" 2>/dev/null)
        [ -n "$match" ] && { echo "$match"; return; }
    done
    echo ""
}
