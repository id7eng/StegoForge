MD_NAME="PDF Analysis"
MD_DESC="Analyze PDF: text extraction, comments, data after EOF, flag patterns"
MD_TYPES="pdf"
MD_DEPS="python3"
MD_PRIORITY=38
MD_PRODUCES="pdf_data flag"

analyze_pdf_analysis() {
    local f="$1"
    header "PDF Analysis" "Multi-Layer PDF Detection"

    # Text extraction via pdftotext
    if command -v pdftotext &>/dev/null; then
        local text=$(pdftotext "$f" - 2>/dev/null | tr -d '\0')
        if [ -n "$text" ]; then
            # Emit all lines
            while IFS= read -r line; do
                [ -z "$line" ] && continue
                emit "pdf_data" "PDF text: $line"
            done < <(echo "$text")
            # Match flag patterns
            local combined=""
            for p in "${FLAG_PATTERNS[@]}"; do
                [ -n "$combined" ] && combined+="|"
                combined+="$p"
            done
            [ -n "$combined" ] && while IFS= read -r m; do
                [ -n "$m" ] && emit "flag" "$m"
            done < <(echo "$text" | grep -oP "$combined" 2>/dev/null)

            # Partial flag / tail detection
            while IFS= read -r partial; do
                [ -n "$partial" ] && emit "partial_flag" "Tail: $partial"
            done < <(echo "$text" | grep -oP '[a-zA-Z0-9_!@#$%^&*()+\-]{6,}\}' 2>/dev/null)
        fi
    fi

    # Data after %%EOF
    export PDF_FILE="$f"
    while IFS= read -r line; do
        [ -z "$line" ] && continue
        emit "pdf_data" "After EOF: $line"
    done < <(python3 -c "
import os
with open(os.environ['PDF_FILE'], 'rb') as f:
    data = f.read()
eof_pos = data.rfind(b'%%EOF')
if eof_pos != -1 and eof_pos + 5 < len(data):
    extra = data[eof_pos+5:].strip()
    if extra:
        import re
        texts = re.findall(b'[A-Za-z0-9_{}]{4,}', extra)
        for t in texts:
            print(t.decode('ascii', errors='replace'))
" 2>/dev/null)
    unset PDF_FILE

    # PDF comments
    export PDF_FILE="$f"
    while IFS= read -r line; do
        [ -z "$line" ] && continue
        emit "pdf_data" "$line"
    done < <(python3 -c "
import os
with open(os.environ['PDF_FILE'], 'rb') as f:
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
" 2>/dev/null)
    unset PDF_FILE
}
