# ─────────────────────────────────────────────
# CTFtime Connector — Fetches writeups from CTFtime.org
# ─────────────────────────────────────────────
# Gets the latest writeups from CTFtime's writeup page

name() { echo "CTFtime Writeups"; }

# Getting writeups from CTFtime's API
# CTFtime provides an event/writeups API

discover() {
    local source_id="$1" base_url="$2"
    local year="${3:-2026}"
    db_log "CTFTIME" "Fetching writeups for $year..."

    # Default to CTFtime writeup page
    local writeup_page_url="https://ctftime.org/writeups"
    [ -n "$base_url" ] && [ "$base_url" != "ctftime" ] && writeup_page_url="$base_url"

    # Fetch the writeup listing page
    local page=$(timeout 20 curl -sL "$writeup_page_url" 2>/dev/null)
    [ -z "$page" ] && { db_log "CTFTIME" "Cannot fetch CTFtime page"; return; }

    # Parse writeup links from the page
    echo "$page" | python3 -c "
import sys, re
html = sys.stdin.read()

# CTFtime writeup page format:
# Each writeup is in a table row with links to writeup URLs
# Pattern: <a href=\"https://...\"> (external writeup link)

# Find all writeup links (external links)
writeup_links = re.findall(r'href=[\"\\'](https?://[^\"\\']+writeup[^\"\\']*)[\"\\']', html, re.IGNORECASE)

# Also find any ctf-related links that point to full writeups
alt_links = re.findall(r'href=[\"\\'](https?://[^\"\\']+(writeup|ctf|solution|flag)[^\"\\']*)[\"\\']', html, re.IGNORECASE)

seen = set()
for link in writeup_links:
    if link not in seen:
        seen.add(link)
        print(f'{link}|CTFtime Writeup|ctftime')

for link, _ in alt_links:
    if link not in seen:
        seen.add(link)
        print(f'{link}|CTFtime Writeup|ctftime')
" 2>/dev/null | head -100
}

fetch() {
    local source_id="$1" base_url="$2" article_url="$3"
    timeout 20 curl -sL "$article_url" 2>/dev/null
}
