MD_NAME="DTMF"
MD_DESC="Decode DTMF phone tones from audio"
MD_TYPES="wav"
MD_DEPS="multimon-ng"
MD_PRIORITY=53
MD_PRODUCES="dtmf_data flag"

analyze_dtmf() {
    local f="$1"
    header "DTMF" "Phone Tone Decoding"

    local out=$(multimon-ng -t wav -a DTMF "$f" 2>/dev/null)
    local dtmf=$(echo "$out" | grep "DTMF:" | head -5)
    [ -n "$dtmf" ] && while IFS= read -r line; do
        emit "dtmf_data" "DTMF: $line"
    done <<< "$dtmf"
}
