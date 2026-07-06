declare -A MODULE_CONFIDENCE
CONFIDENCE_MIN="${CONFIDENCE_MIN:-40}"

load_confidence_weights() {
    MODULE_CONFIDENCE=(
        ["metadata"]=95 ["exif_thumbnail"]=90 ["qr"]=88
        ["base64_full"]=92 ["strings"]=40 ["flag_scanner"]=30
        ["xor_brute"]=60 ["rot_brute"]=55 ["zsteg"]=80
        ["steghide"]=85 ["stegseek"]=85 ["outguess"]=80
        ["binwalk"]=75 ["foremost"]=75 ["ocr"]=85
        ["pdf_analysis"]=80 ["video"]=70 ["spectrogram"]=60
        ["snow"]=75 ["zero_width"]=75 ["stepic"]=80
        ["cross_lsb"]=80 ["bit_plane"]=75 ["gif_palette"]=75
        ["png_crc"]=70 ["png_check"]=70 ["smart_wordlist"]=65
        ["stegdetect"]=50 ["append_data"]=60 ["jpeg_dqt"]=65
        ["binary_border"]=60 ["fft_domain"]=50 ["audio_reverse"]=60
        ["mp3stego"]=75 ["sstv"]=70 ["dtmf"]=60
        ["disk_forensics"]=70 ["pcap_analysis"]=75 ["polyglot_detector"]=50
        ["repair"]=50 ["quick_scan"]=30 ["ads_scan"]=50
        ["olevba"]=80 ["zip_brute"]=80 ["image_magick"]=50
        ["jphide"]=75 ["f5"]=75 ["stegseek"]=85
        ["binary_digits"]=70 ["snow"]=75 ["zero_width"]=75
        ["default"]=40
    )
}

score_confidence() {
    local module="$1" data="$2" pattern_type="${3:-generic}" ftype="${4:-}"
    local base="${MODULE_CONFIDENCE[$module]:-${MODULE_CONFIDENCE[default]}}"
    is_known_pattern "$data" && [ "$base" -lt 70 ] && base=70
    [ "$pattern_type" = "known" ] && { echo "$base"; return; }

    # Adjust from KB statistics if available
    if [ -n "$ftype" ] && [ -f "${KNOWLEDGE_DIR}/knowledge.db" ]; then
        local stats=$(sqlite3 -separator '|' "${KNOWLEDGE_DIR}/knowledge.db" "SELECT confidence, total_count FROM statistics WHERE file_type='$ftype' AND tool='$module' AND total_count > 2 ORDER BY total_count DESC LIMIT 1" 2>/dev/null)
        if [ -n "$stats" ]; then
            local kb_conf=$(echo "$stats" | cut -d'|' -f1)
            local kb_count=$(echo "$stats" | cut -d'|' -f2)
            local kb_pct=$(echo "$kb_conf * 100 / 1" | bc 2>/dev/null)
            if [ -n "$kb_pct" ] && [ "$kb_pct" -gt 0 ]; then
                base=$(( (base * 3 + kb_pct * 2) / 5 ))
            fi
        fi
    fi

    local len=${#data}
    [ "$len" -lt 10 ] && base=$((base - 20))
    [ "$len" -gt 100 ] && base=$((base - 10))
    local alpha=$(echo "$data" | tr -cd 'a-zA-Z' | wc -c)
    local digit=$(echo "$data" | tr -cd '0-9' | wc -c)
    local total=$((len > 0 ? len : 1))
    local char_ratio=$(( (alpha + digit) * 100 / total ))
    [ "$char_ratio" -lt 40 ] && base=$((base - 15))
    [ "$char_ratio" -gt 80 ] && base=$((base + 5))
    echo "$data" | grep -qiE 'flag|ctf|key|secret|pass' && base=$((base + 10))
    [ "$base" -gt 100 ] && base=100
    [ "$base" -lt 0 ] && base=0
    echo "$base"
}

is_known_pattern() {
    local data="$1"
    local known="picoCTF|HTB|THM|NCSE|FLAG|flag|CTF"
    echo "$data" | grep -qE "^($known)\{" 2>/dev/null
}

