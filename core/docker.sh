DOCKER_IMAGE="stegoforge:latest"

docker_check() {
    command -v docker &>/dev/null
}

docker_image_exists() {
    docker image inspect "$DOCKER_IMAGE" &>/dev/null 2>&1
}

docker_build() {
    local dir="$1"
    info "Building Docker image (first run only)..."
    docker build -t "$DOCKER_IMAGE" "$dir" 2>&1 | tail -3
}

docker_native_ok() {
    local needed=("file" "xxd" "strings" "python3" "binwalk" "foremost" "steghide" "exiftool" "ffmpeg" "sox" "fcrackzip" "tesseract")
    local missing=0
    for dep in "${needed[@]}"; do
        command -v "$dep" &>/dev/null || missing=$((missing + 1))
    done
    [ "$missing" -le 3 ]
}

docker_run_analyze() {
    local f="$1"
    shift
    local args=("$@")
    local real_f=$(realpath "$f" 2>/dev/null || echo "$f")
    local f_dir=$(dirname "$real_f")
    local f_base=$(basename "$real_f")

    [ -z "$OUTDIR" ] && OUTDIR="/tmp/stegoforge_output"
    mkdir -p "$OUTDIR"
    local outdir_real=$(realpath "$OUTDIR")

    docker run --rm \
        -v "$f_dir:/work:ro" \
        -v "$outdir_real:/output" \
        -e "OUTDIR=/output" \
        "$DOCKER_IMAGE" \
        "${args[@]}" "/work/$f_base" 2>/dev/null
}
