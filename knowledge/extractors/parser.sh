# ─────────────────────────────────────────────
# Writeup Parser — Extracts structured knowledge from writeup content
# ─────────────────────────────────────────────

parse_writeup() {
    local content="$1" url="$2"
    local file_ext="${url##*.}"

    case "$file_ext" in
        pdf)  content=$(parse_pdf "$url") ;;
        html) content=$(parse_html "$content") ;;
    esac

    local title=$(extract_title "$content")
    local category=$(extract_category "$content")
    local challenge=$(extract_challenge "$content")
    local pub_date=$(extract_date "$content")
    local summary=$(extract_summary "$content")
    local lang="en"

    echo "TITLE:$title"
    echo "CATEGORY:$category"
    echo "CHALLENGE:$challenge"
    echo "DATE:$pub_date"
    echo "SUMMARY:$summary"
    echo "LANG:$lang"
    echo "---CONTENT---"
    echo "$content"
}

parse_pdf() {
    local file="$1"
    if command -v pdftotext &>/dev/null; then
        pdftotext "$file" - 2>/dev/null
    elif command -v python3 &>/dev/null; then
        python3 -c "
import sys
try:
    import subprocess
    result = subprocess.run(['pdftotext', '$file', '-'], capture_output=True, text=True)
    print(result.stdout)
except: print('')
" 2>/dev/null
    else
        strings "$file" 2>/dev/null | head -500
    fi
}

parse_html() {
    local content="$1"
    echo "$content" | python3 -c "
import sys, re
html = sys.stdin.read()
# Remove scripts and styles
html = re.sub(r'<script[^>]*>.*?</script>', '', html, flags=re.DOTALL|re.IGNORECASE)
html = re.sub(r'<style[^>]*>.*?</style>', '', html, flags=re.DOTALL|re.IGNORECASE)
# Convert block tags to newlines
html = re.sub(r'</?(p|div|br|h[1-6]|li|tr|pre|code)[^>]*>', '\n', html, flags=re.IGNORECASE)
# Remove remaining HTML tags
text = re.sub(r'<[^>]+>', '', html)
# Decode common entities
text = text.replace('&amp;', '&').replace('&lt;', '<').replace('&gt;', '>').replace('&quot;', '\"').replace('&#39;', \"'\")
lines = [l.strip() for l in text.split('\n') if l.strip()]
print('\n'.join(lines))
" 2>/dev/null
}

extract_title() {
    local content="$1"
    echo "$content" | head -20 | grep -m1 -iE '^#\s+|^title:\s+|^<h1' | sed 's/^#\+\s*//; s/^title:\s*//i; s/<[^>]*>//g' | head -1
    # fallback: first non-empty line
    if [ -z "$(echo "$content" | head -20 | grep -m1 -iE '^#\s+|^title:\s+|^<h1' | sed 's/^#\+\s*//; s/^title:\s*//i; s/<[^>]*>//g')" ]; then
        echo "$content" | head -5 | grep -m1 '.'
    fi
}

extract_category() {
    local content="$1"
    local cat=$(echo "$content" | grep -m1 -iE '(category|categorie|cat)[:：\s]+' | sed 's/.*[:：]\s*//i' | head -1)
    echo "${cat:-unknown}"
}

extract_challenge() {
    local content="$1"
    local chal=$(echo "$content" | grep -m1 -iE '(challenge|chall|task|problem)[:：\s]+' | sed 's/.*[:：]\s*//i' | head -1)
    echo "${chal:-$(extract_title "$content")}"
}

extract_date() {
    local content="$1"
    echo "$content" | grep -m1 -oE '(19|20)[0-9]{2}[-/][0-9]{2}[-/][0-9]{2}'
}

extract_summary() {
    local content="$1"
    echo "$content" | head -30 | grep -vE '^#|^$' | head -3 | tr '\n' ' ' | cut -c1-200
}

# ─── Extract specific knowledge types ───

extract_tools() {
    local content="$1"
    local known_tools="strings|exiftool|binwalk|foremost|steghide|stegseek|zsteg|outguess|jphide|f5|stegdetect|pngcheck|pngcrc|zlib|xxd|hexdump|hd|dd|file|grep|awk|sed|sort|uniq|base64|base32|xxd -r|openssl|gpg|john|hashcat|fcrackzip|zipinfo|unzip|tar|7z|pngcrush|optipng|exiv2|identify|convert|sox|audacity|wavestego|mp3stego|spectrum|sstv|qr|zbar|python3|perl|ruby|java|wireshark|tshark|tcpdump|volatility|sleuthkit|dcfldd|guymager|testdisk|photorec|scalpel|bulk_extractor"
    echo "$content" | grep -oiE "\b($known_tools)\b" | sort -u
}

extract_commands() {
    local content="$1"
    echo "$content" | grep -E '^\s*(\$|#|>|─|→)\s+' | sed 's/^[\s\$#>─→]*//' | sed 's/^#.*//' | grep -vE '^$' | head -50
    echo "$content" | grep -E '\$(binwalk|steghide|zsteg|exiftool|strings|foremost|outguess)' | sed 's/.*\$//' | sed 's/\$//' | head -30
}

extract_techniques() {
    local content="$1"
    local known="lsb|msb|bit.pla?ne|palette|color.table|dct|dqt|jfif|exif|xmp|chunk|crc|checksum|padding|append|embed|extract|decode|encod|xor|rot|cipher|base64|base32|hex|binar|frequency|fft|spectrogram|audio.reverse|phase|echo|stereo|meta.da|polyglot|magic.byte|signature|carving|forensic|disk.image|memory|volatil|registry|timeline|png|jpg|gif|bmp|wav|mp3|zip|rar|pdf"
    echo "$content" | grep -oiE "\b($known)\b" | sort -u
}

extract_passwords() {
    local content="$1"
    echo "$content" | grep -oiE '(password|pass|pwd|key|secret)[:：\s]*"?[A-Za-z0-9_!@#$%^&*(){}]{4,}"?' | sed 's/.*[:：]\s*"?//; s/"$//' | head -20
}

extract_flag_patterns() {
    local content="$1"
    echo "$content" | grep -oE '(flag|ctf|ncse|pico|shellctf|hacker101)\{[^}]{1,200}\}' | sort -u | head -20
}

extract_file_types() {
    local content="$1"
    local known_types="JPEG|JPG|PNG|GIF|BMP|TIFF|WEBP|SVG|ICO|PSD|WAV|MP3|FLAC|OGG|AAC|M4A|WMA|ZIP|RAR|7Z|TAR|GZ|BZ2|XZ|PDF|DOC|DOCX|XLS|PPT|ELF|PE|Mach-O|PCAP|PCAPNG|DLL|EXE|APK|DEX|CLASS|JAR|ISO|IMG|VHD|QCOW"
    echo "$content" | grep -oiE "\b($known_types)\b" | sort -u
}

extract_encodings() {
    local content="$1"
    local known="base64|base32|base16|hex|ascii|utf[-_]?8|utf[-_]?16|url.encode|percent.encode|rot13|rot47|binary|octal|xor|cipher|caesar|vigenere|aes|des|rsa|md5|sha1|sha256"
    echo "$content" | grep -oiE "\b($known)\b" | sort -u
}

extract_os() {
    local content="$1"
    echo "$content" | grep -oiE "\b(Windows|Linux|Ubuntu|Debian|CentOS|Kali|Parrot|macOS|iOS|Android|FreeBSD|OpenBSD)\b" | sort -u
}

extract_indicators() {
    local content="$1"
    echo "$content" | grep -oiE "(trailing|appended|extra.data|hidden|embedded|encrypt|obfuscat|suspicious|anomal|corrupt|broken|modified|notice|interesting|found|extract|solved|flag)" | sort -u
}
