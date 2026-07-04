# ─────────────────────────────────────────────
# GitHub Connector — Fetches writeups from GitHub repos
# ─────────────────────────────────────────────
# Uses GitHub API to list repo contents and fetch files.

name() { echo "GitHub Repository"; }

discover() {
    local source_id="$1" repo_url="$2"
    # Normalize URL: github.com/user/repo
    local repo=$(echo "$repo_url" | sed -E 's|https?://github.com/||; s|\.git$||; s|/$||')
    local api_url="https://api.github.com/repos/${repo}/contents"

    db_log "GITHUB" "Scanning repo: $repo"

    local items=$(timeout 30 curl -sL "$api_url" 2>/dev/null | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    for item in data if isinstance(data, list) else []:
        name = item.get('name', '')
        dtype = item.get('type', '')
        durl = item.get('download_url', '') or item.get('html_url', '')
        ext = name.lower().rsplit('.', 1)[-1] if '.' in name else ''
        if dtype == 'file' and ext in ('md','txt','html','pdf','rst'):
            print(f\"{durl}|{name}\")
        elif dtype == 'dir':
            print(f\"DIR:{item.get('url','')}|{name}\")
except: pass
" 2>/dev/null)

    local has_more=false
    while IFS='|' read -r url name; do
        [ -z "$url" ] && continue
        if echo "$url" | grep -q "^DIR:"; then
            local dir_url="${url#DIR:}"
            local sub_items=$(timeout 15 curl -sL "$dir_url" 2>/dev/null | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    for item in data if isinstance(data, list) else []:
        durl = item.get('download_url', '') or item.get('html_url', '')
        n = item.get('name', '')
        ext = n.lower().rsplit('.', 1)[-1] if '.' in n else ''
        if item.get('type') == 'file' and ext in ('md','txt','html','pdf','rst'):
            print(f'{durl}|{n}')
except: pass
" 2>/dev/null)
            while IFS='|' read -r sub_url sub_name; do
                [ -n "$sub_url" ] && echo "$sub_url|$sub_name|$repo"
            done <<< "$sub_items"
        else
            echo "$url|$name|$repo"
        fi
    done <<< "$items"
}

fetch() {
    local source_id="$1" repo_url="$2" file_url="$3"
    timeout 30 curl -sL "$file_url" 2>/dev/null
}

fetch_raw() {
    local file_url="$1"
    timeout 30 curl -sL "$file_url" 2>/dev/null
}
