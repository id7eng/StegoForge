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

    info "Attempting steghide extraction with empty password"
    run_cmd steghide extract -sf "$f" -p "" -xf "$extract_out" -f >/dev/null 2>&1
    if [ -f "$extract_out" ]; then
        local content=$(cat "$extract_out" 2>/dev/null)
        info "Extracted data with empty password"
        save_artifact "$extract_out" "$f" "steghide"
        emit_finding "steghide_data" "Empty password: $content"
        rm -f "$extract_out" 2>/dev/null
        return
    fi

    [ -z "$wl" ] || [ ! -f "$wl" ] && wl="$SMART_WL"
    [ -z "$wl" ] || [ ! -f "$wl" ] && {
        info "No wordlist available, skipping brute-force"
        return
    }

    if command -v stegseek &>/dev/null; then
        info "Using stegseek (fast)..."
        run_cmd stegseek "$f" "$wl" -o "$extract_out" --quiet
        if [ -f "$extract_out" ]; then
            local pass=$(stegseek "$f" "$wl" 2>&1 | grep -oP 'password: \K.*' | head -1)
            info "StegSeek found password: $pass"
            [ -n "$pass" ] && emit_password "Password: $pass"
            local content=$(cat "$extract_out" 2>/dev/null)
            [ -n "$content" ] && emit_finding "steghide_data" "$content"
            save_artifact "$extract_out" "$f" "steghide"
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
        run_cmd steghide extract -sf "$f" -p "$p" -xf "$extract_out" -f >/dev/null 2>&1
        if [ -f "$extract_out" ]; then
            info "Password found via brute-force: $p"
            local content=$(cat "$extract_out" 2>/dev/null)
            emit_password "Password: $p"
            emit_finding "steghide_data" "$content"
            save_artifact "$extract_out" "$f" "steghide"
            rm -f "$extract_out" 2>/dev/null
            return
        fi
    done < "$wl"
    info "No password found"
}
