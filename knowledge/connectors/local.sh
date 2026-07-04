# ─────────────────────────────────────────────
# Local Connector — Reads writeups from local filesystem
# ─────────────────────────────────────────────

name() { echo "Local Filesystem"; }

discover() {
    local source_id="$1" dir_path="$2"
    [ -d "$dir_path" ] || { db_log "LOCAL" "Directory not found: $dir_path"; return; }
    db_log "LOCAL" "Scanning: $dir_path"
    local exts="md txt html pdf rst"
    for ext in $exts; do
        while IFS= read -r -d '' f; do
            local name=$(basename "$f")
            echo "$f|$name|local"
        done < <(find "$dir_path" -name "*.$ext" -type f -print0 2>/dev/null)
    done
}

fetch() {
    local source_id="$1" base_path="$2" file_path="$3"
    [ -f "$file_path" ] && cat "$file_path"
}
