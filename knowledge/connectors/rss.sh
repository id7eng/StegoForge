# ─────────────────────────────────────────────
# RSS/Atom Connector — Fetches writeups from RSS/Atom feeds
# ─────────────────────────────────────────────
# Supports: Medium blogs, personal blogs, CTF news sites
# Url example: https://medium.com/feed/@username
#              https://example.com/blog/rss

name() { echo "RSS/Atom Feed"; }

discover() {
    local source_id="$1" feed_url="$2"
    db_log "RSS" "Discovering from feed: $feed_url"

    local feed_content=$(timeout 15 curl -sL "$feed_url" 2>/dev/null)
    [ -z "$feed_content" ] && { db_log "RSS" "Cannot fetch feed"; return; }

    # Parse RSS/Atom entries using Python
    echo "$feed_content" | python3 -c "
import sys, xml.etree.ElementTree as ET, re

content = sys.stdin.read()
if not content.strip():
    sys.exit(0)

try:
    root = ET.fromstring(content)
except:
    # Try to clean common issues
    content = re.sub(r'<[?]xml[^>]+>', '', content)
    content = '<root>' + content + '</root>'
    try:
        root = ET.fromstring(content)
    except:
        sys.exit(0)

entries = []

# RSS 2.0
for item in root.iter('item'):
    link = ''
    title = ''
    for child in item:
        if child.tag == 'link':
            link = child.text or ''
        elif child.tag == 'title':
            title = child.text or ''
    if link and ('ctf' in link.lower() or 'write' in link.lower() or 'flag' in link.lower() or 'stego' in link.lower() or 'forensic' in link.lower()):
        entries.append(f'{link}|{title}|rss')

# Atom
for entry in root.iter('{http://www.w3.org/2005/Atom}entry'):
    link = ''
    title = ''
    for child in entry:
        if child.tag == '{http://www.w3.org/2005/Atom}link':
            link = child.attrib.get('href', '')
        elif child.tag == '{http://www.w3.org/2005/Atom}title':
            title = child.text or ''
    if link and ('ctf' in link.lower() or 'write' in link.lower() or 'flag' in link.lower() or 'stego' in link.lower() or 'forensic' in link.lower()):
        entries.append(f'{link}|{title}|rss')

# RSS 1.0 (RDF)
for item in root.iter('{http://purl.org/rss/1.0/}item'):
    link = ''
    title = ''
    for child in item:
        if child.tag == '{http://purl.org/rss/1.0/}link':
            link = child.text or ''
        elif child.tag == '{http://purl.org/rss/1.0/}title':
            title = child.text or ''
    if link and ('ctf' in link.lower() or 'write' in link.lower() or 'flag' in link.lower() or 'stego' in link.lower() or 'forensic' in link.lower()):
        entries.append(f'{link}|{title}|rss')

for e in entries:
    print(e)

if not entries:
    # If no CTF-related entries, show all as generic writeup candidates
    for item in root.iter('item'):
        link = ''
        for child in item:
            if child.tag == 'link':
                link = child.text or ''
        if link:
            print(f'{link}||rss')
    for entry in root.iter('{http://www.w3.org/2005/Atom}entry'):
        link = ''
        for child in entry:
            if child.tag == '{http://www.w3.org/2005/Atom}link':
                link = child.attrib.get('href', '')
        if link:
            print(f'{link}||rss')
" 2>/dev/null
}

fetch() {
    local source_id="$1" feed_url="$2" article_url="$3"
    timeout 15 curl -sL "$article_url" 2>/dev/null
}
