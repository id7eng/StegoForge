MD_NAME="FFT Domain"
MD_DESC="Frequency domain analysis of images (FFT pattern detection)"
MD_TYPES="jpg jpeg png bmp gif"
MD_DEPS="python3"
MD_PRIORITY=49
MD_PRODUCES="fft_pattern flag"

analyze_fft_domain() {
    local f="$1"
    header "FFT Domain" "Frequency Domain Analysis"

    local outfile="${OUTDIR}/carved/fft_analysis.txt"

    export FFT_FILE="$f"
    while read line; do
        emit "fft_pattern" "FFT: $line"
    done < <(run_cmd python3 -c "
import os, sys
try:
    import numpy as np
    from PIL import Image
except ImportError:
    sys.exit(0)

try:
    img = Image.open(os.environ['FFT_FILE']).convert('L')
    arr = np.array(img, dtype=float)
except Exception:
    sys.exit(0)

fft = np.fft.fft2(arr)
fft_shift = np.fft.fftshift(fft)
magnitude = np.abs(fft_shift)
phase = np.angle(fft_shift)

# Look for text in magnitude spectrum
mag_norm = ((magnitude - magnitude.min()) / (magnitude.max() - magnitude.min() + 1e-10) * 255).astype(np.uint8)

# Detect unusual patterns
rows, cols = mag_norm.shape
center_r, center_c = rows // 2, cols // 2

# Check for ring patterns (concentric circles = frequency data)
threshold = mag_norm.mean() * 1.5
anomalies = np.where(mag_norm > threshold)

if len(anomalies[0]) > 10:
    print(f'Unusual frequency components: {len(anomalies[0])} pixels above threshold')

# Check LSB of phase for hidden data
phase_bits = ((phase * 100).astype(int) & 1).flatten()[:800]
chars = ''
for i in range(0, len(phase_bits) - len(phase_bits) % 8, 8):
    b = ''.join(str(phase_bits[i+j]) for j in range(8))
    c = int(b, 2)
    if 32 <= c <= 126:
        chars += chr(c)
if len(chars) > 3:
    print(f'Phase LSB: {chars}')
")
    unset FFT_FILE
}
