MD_NAME="Audio Reverse"
MD_DESC="Reverse audio and search for hidden flags"
MD_TYPES="wav mp3 au"
MD_DEPS="sox"
MD_PRIORITY=51
MD_PRODUCES="reversed_data flag"

analyze_audio_reverse() {
    local f="$1"
    header "Audio Reverse" "Reversed Audio Analysis"

    local reversed_file="${OUTDIR}/carved/reversed_audio.wav"
    sox "$f" "$reversed_file" reverse 2>/dev/null || {
        info "sox reverse failed"
        return
    }

    local text=$(strings "$reversed_file" 2>/dev/null | grep -v "^$" | head -10)
    [ -n "$text" ] && while IFS= read -r line; do
        emit "reversed_data" "Reversed text: $line"
    done <<< "$text"

    python3 -c "
import wave, re
try:
    with wave.open('$reversed_file', 'rb') as w:
        frames = w.readframes(w.getnframes())
    texts = re.findall(b'[A-Za-z0-9_{}]{4,}', frames)
    for t in texts:
        print(t.decode('ascii', errors='replace'))
except Exception:
    pass
" 2>/dev/null | while read line; do
        emit "reversed_data" "Audio bytes: $line"
    done

    rm -f "$reversed_file" 2>/dev/null
}
