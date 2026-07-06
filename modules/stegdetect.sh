MD_NAME="StegDetect"
MD_DESC="Detect JPEG steganography tool used (jphide, outguess, jsteg, F5)"
MD_TYPES="jpg jpeg"
MD_DEPS="stegdetect"
MD_PRIORITY=15
MD_PRODUCES="steg_tool"

analyze_stegdetect() {
    local f="$1"
    header "StegDetect" "JPEG Steganography Tool Detection"
    local out=$(run_cmd stegdetect -t jphide,outguess,jsteg,f5 "$f")
    local tool=$(echo "$out" | sed 's/.*: *//' | head -1)
    [ -z "$tool" ] && tool="negative"
    if echo "$tool" | grep -qv "negative"; then
        emit "steg_tool" "Detected: $tool"
    fi
}
