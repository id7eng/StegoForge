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
    run_cmd sox "$f" "$reversed_file" reverse || {
        info "sox reverse failed"
        return
    }

    local text=$(run_cmd strings "$reversed_file" | grep -v "^$" | head -10)
    [ -n "$text" ] && while IFS= read -r line; do
        emit "reversed_data" "Reversed text: $line"
    done <<< "$text"

    export AUDIO_REVERSED_FILE="$reversed_file"
    while read line; do
        emit "reversed_data" "Audio bytes: $line"
    done < <(run_cmd python3 -c "
import os, wave, re
try:
    with wave.open(os.environ['AUDIO_REVERSED_FILE'], 'rb') as w:
        frames = w.readframes(w.getnframes())
    texts = re.findall(b'[A-Za-z0-9_{}]{4,}', frames)
    for t in texts:
        print(t.decode('ascii', errors='replace'))
except Exception:
    pass
")
    unset AUDIO_REVERSED_FILE

    rm -f "$reversed_file" 2>/dev/null
}
