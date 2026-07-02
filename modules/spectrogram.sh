MD_NAME="Spectrogram"
MD_DESC="Audio spectrogram visualization"
MD_TYPES="wav au mp3 wave"
MD_DEPS="python3-scipy python3-matplotlib"
MD_PRIORITY=50
MD_PRODUCES="spectrogram"

analyze_spectrogram() {
    local f="$1"
    header "Spectrogram" "Audio Analysis"
    local out="${OUTDIR}/spectrograms/$(basename "$f").png"
    python3 -c "
try:
    import numpy as np, matplotlib.pyplot as plt
    from scipy.io import wavfile
    sr, data = wavfile.read('$f')
    if len(data.shape) > 1: data = data[:, 0]
    plt.specgram(data, Fs=sr, NFFT=512, cmap='gray')
    plt.savefig('$out', dpi=150, bbox_inches='tight')
    print(f'OK: $out')
except Exception as e:
    print(f'ERR: {e}')
" 2>/dev/null | while read line; do
        case "$line" in
            OK:*) emit "spectrogram" "Spectrogram → ${line#OK:}" ;;
            ERR:*) info "${line#ERR:}" ;;
        esac
    done
}
