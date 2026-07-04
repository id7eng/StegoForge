MD_NAME="Steghide"
MD_DESC="Steghide extraction + brute-force"
MD_TYPES="jpg jpeg bmp wav"
MD_DEPS="steghide"
MD_PRIORITY=40
MD_PRODUCES="steghide_data password flag"

analyze_steghide() {
    local f="$1" wl="$2"
    local extract_out="${OUTDIR}/carved/steghide_out"
    header "Steghide" "JPEG/BMP/WAV Steganography"
    if ! command -v steghide &>/dev/null; then
        info "steghide not installed"
        return
    fi

    steghide extract -sf "$f" -p "" -xf "$extract_out" -f >/dev/null 2>&1
    if [ -f "$extract_out" ]; then
        local content=$(cat "$extract_out" 2>/dev/null)
        emit "steghide_data" "Empty password: $content"
        rm -f "$extract_out" 2>/dev/null
        return
    fi

    [ -z "$wl" ] || [ ! -f "$wl" ] && wl="$SMART_WL"
    [ -z "$wl" ] || [ ! -f "$wl" ] && return

    if command -v stegseek &>/dev/null; then
        info "Using stegseek (fast)..."
        stegseek "$f" "$wl" -o "$extract_out" --quiet 2>/dev/null
        if [ -f "$extract_out" ]; then
            local pass=$(stegseek "$f" "$wl" 2>&1 | grep -oP 'password: \K.*' | head -1)
            [ -n "$pass" ] && emit "password" "Password: $pass"
            local content=$(cat "$extract_out" 2>/dev/null)
            [ -n "$content" ] && emit "steghide_data" "$content"
            rm -f "$extract_out" 2>/dev/null
            return
        fi
        info "StegSeek found nothing"
        return
    fi

    info "Brute-forcing with wordlist..."
    while IFS= read -r raw; do
        [ -z "$raw" ] && continue
        local p="${raw##* }"
        [ -z "$p" ] && continue
        steghide extract -sf "$f" -p "$p" -xf "$extract_out" -f >/dev/null 2>&1
        if [ -f "$extract_out" ]; then
            local content=$(cat "$extract_out" 2>/dev/null)
            emit "password" "Password: $p"
            emit "steghide_data" "$content"
            rm -f "$extract_out" 2>/dev/null
            return
        fi
    done < "$wl"
    info "No password found"
}
