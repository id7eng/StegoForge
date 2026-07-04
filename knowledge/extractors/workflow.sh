# ─────────────────────────────────────────────
# Workflow Extractor — Extracts analysis steps from writeup content
# ─────────────────────────────────────────────

extract_workflow() {
    local content="$1"

    # Pattern 1: Numbered lists (1. step, 2. step)
    local numbered=$(echo "$content" | grep -oE '^[[:space:]]*[0-9]+[.)][[:space:]].+' | sed 's/^[[:space:]]*[0-9]+[.)][[:space:]]*//')
    [ -n "$numbered" ] && { echo "$numbered"; return; }

    # Pattern 2: Arrow notation (step → step → step)  
    local arrows=$(echo "$content" | grep -oE '[A-Z][a-z]+ → [A-Z][a-z]+')
    [ -n "$arrows" ] && echo "$arrows"

    # Pattern 3: Bullet list with tool names
    echo "$content" | grep -E '^\s*[\*\-]\s+' | grep -iE "(strings|exiftool|binwalk|steghide|zsteg|foremost|outguess)" | sed 's/^[\s\*\-]*//'

    # Pattern 4: Lines containing command invocations in order
    local cmds=$(echo "$content" | grep -n -E '(strings|exiftool|binwalk|steghide|zsteg|foremost|outguess|pngcheck|stegseek)' | head -20)
    [ -n "$cmds" ] && echo "$cmds" | sed 's/^[0-9]*://' | head -10
}

workflow_to_steps() {
    local raw="$1" writeup_id="$2"
    local step=0

    while IFS= read -r line; do
        [ -z "$line" ] && continue
        step=$((step + 1))

        local tool=""
        local action=""
        local params=""

        # Detect tool
        for t in strings exiftool binwalk foremost steghide stegseek zsteg outguess jphide f5 stegdetect pngcheck pngcrc zsteg spectrogram sstv qr zipinfo unzip dd xxd file base64 python3 perl; do
            if echo "$line" | grep -qiw "$t"; then
                tool="$t"
                break
            fi
        done

        # Detect action type
        if echo "$line" | grep -qiE '(run|execute|use|launch)'; then
            action="run"
        elif echo "$line" | grep -qiE '(extract|get|find|obtain)'; then
            action="extract"
        elif echo "$line" | grep -qiE '(check|analyze|scan|inspect)'; then
            action="analyze"
        elif echo "$line" | grep -qiE '(decode|decrypt|decompress)'; then
            action="decode"
        elif echo "$line" | grep -qiE '(search|grep|look)'; then
            action="search"
        else
            action="process"
        fi

        # Extract parameters after tool name
        if [ -n "$tool" ]; then
            params=$(echo "$line" | sed "s/.*$tool//" | cut -c1-100)
        fi

        echo "STEP:$step|$action|$tool|$params"
    done <<< "$raw"
}
