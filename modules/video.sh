MD_NAME="Video"
MD_DESC="Extract frames from video and analyze for hidden data"
MD_TYPES="mp4 avi mov mkv webm"
MD_DEPS="ffmpeg"
MD_PRIORITY=12
MD_PRODUCES="video_frame flag"

analyze_video() {
    local f="$1"
    header "Video" "Frame Extraction & Analysis"

    local frame_dir="${OUTDIR}/carved/video_frames"
    mkdir -p "$frame_dir"

    info "Extracting frames..."
    ffmpeg -i "$f" -vf "fps=1" "${frame_dir}/frame_%04d.png" -loglevel quiet -y 2>/dev/null

    local count=$(ls "${frame_dir}"/*.png 2>/dev/null | wc -l)
    [ "$count" -eq 0 ] && { info "No frames extracted"; return; }
    info "Extracted $count frames"

    if command -v zbarimg &>/dev/null; then
        for frame in "${frame_dir}"/*.png; do
            local qr=$(zbarimg --quiet "$frame" 2>/dev/null)
            [ -n "$qr" ] && emit "video_frame" "QR in $(basename $frame): $qr"
        done
    fi

    for frame in "${frame_dir}"/*.png; do
        local text=$(strings "$frame" 2>/dev/null | grep -iE "flag|ctf|secret|key" | head -3)
        [ -n "$text" ] && while IFS= read -r line; do
            emit "video_frame" "Text in $(basename $frame): $line"
        done <<< "$text"
    done

    python3 -c "
import sys
try:
    import numpy as np
    from PIL import Image
    import glob
except ImportError:
    sys.exit(0)

frames = sorted(glob.glob('${frame_dir}/frame_*.png'))
if not frames:
    sys.exit(0)

acc = np.array(Image.open(frames[0]).convert('L'), dtype=float)
for f in frames[1:]:
    acc += np.array(Image.open(f).convert('L'), dtype=float)
acc /= len(frames)
acc_img = Image.fromarray(acc.astype(np.uint8))
acc_img.save('${OUTDIR}/carved/video_accumulated.png')
print('Accumulated image saved (' + str(len(frames)) + ' frames)')
" 2>/dev/null | while read line; do
        info "$line"
    done

    python3 -c "
import sys, os
try:
    import numpy as np
    from PIL import Image
    import glob
except ImportError:
    sys.exit(0)

frames = sorted(glob.glob('${frame_dir}/frame_*.png'))
if len(frames) < 2:
    sys.exit(0)

prev = np.array(Image.open(frames[0]).convert('L'), dtype=float)
for f in frames[1:]:
    curr = np.array(Image.open(f).convert('L'), dtype=float)
    diff = np.abs(curr - prev)
    if diff.max() > 0:
        diff_img = Image.fromarray((diff * (255.0 / diff.max())).astype(np.uint8))
        diff_img.save(os.path.join('${frame_dir}', 'diff_' + os.path.basename(f)))
    prev = curr
print('Frame differencing complete')
" 2>/dev/null | while read line; do
        info "$line"
    done
}
