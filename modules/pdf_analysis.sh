MD_NAME="PDF Analysis"
MD_DESC="Analyze PDF multi-layer steganography, comments, hidden text"
MD_TYPES="pdf"
MD_DEPS="python3"
MD_PRIORITY=38
MD_PRODUCES="pdf_data flag"

analyze_pdf_analysis() {
    local f="$1"
    header "PDF Analysis" "Multi-Layer PDF Detection"

    # Check for data after %%EOF
    python3 -c "
with open('$f', 'rb') as f:
    data = f.read()
eof_pos = data.rfind(b'%%EOF')
if eof_pos != -1 and eof_pos + 5 < len(data):
    extra = data[eof_pos+5:].strip()
    if extra:
        import re
        texts = re.findall(b'[A-Za-z0-9_{}]{4,}', extra)
        for t in texts:
            print(f'After EOF: {t.decode(\"ascii\", errors=\"replace\")}')
" 2>/dev/null | while read line; do
        emit "pdf_data" "$line"
    done

    # Extract text (pdftotext)
    if command -v pdftotext &>/dev/null; then
        local text=$(pdftotext "$f" - 2>/dev/null)
        [ -n "$text" ] && echo "$text" | grep -oP '[A-Za-z0-9_!@#$%^&*(){}]{10,}' 2>/dev/null | while read m; do
            emit "pdf_data" "PDF text: $m"
        done
    fi

    # Check for comments
    python3 -c "
with open('$f', 'rb') as f:
    data = f.read()
import re
comments = re.findall(b'%\s*(.{4,}?)(?:\n|\r)', data)
for c in comments:
    try:
        t = c.decode('ascii', errors='replace').strip()
        if t and not t.startswith('%'):
            print(f'Comment: {t}')
    except:
        pass
" 2>/dev/null | while read line; do
        emit "pdf_data" "$line"
    done
}
