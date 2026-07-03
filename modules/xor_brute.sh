MD_NAME="XOR Brute"
MD_DESC="Single-byte XOR brute-force on file/strings"
MD_TYPES="*"
MD_DEPS="python3"
MD_PRIORITY=80
MD_PRODUCES="xor_key decoded"

analyze_xor_brute() {
    local f="$1"
    header "XOR Brute" "Single-byte XOR key search"

    local targets=$(strings "$f" 2>/dev/null | grep -oE '[A-Za-z0-9+/=]{10,60}' | head -20)
    [ -z "$targets" ] && targets=$(strings "$f" 2>/dev/null | grep -oE '[!-~]{10,60}' | head -10)

    if [ -n "$targets" ]; then
        while IFS= read -r s; do
            [ ${#s} -lt 4 ] && continue
            export XOR_STRING="$s"
            local result=$(python3 -c "
import os, sys
s = os.environ['XOR_STRING']
kw = ['flag', 'ctf', 'ncse', 'pico', 'secret', 'key', 'password', 'FLAG', 'CTF', 'NCSE', 'PICO']
for k in range(256):
    d = ''.join(chr(b ^ k) for b in s.encode())
    for w in kw:
        if w in d:
            safe = d.replace(\"'\", \"'\").replace('\$', ' ')
            print(f'KEY:0x{k:02x} DATA:{safe}')
            sys.exit(0)
" 2>/dev/null)
            unset XOR_STRING
            [ -n "$result" ] && {
                emit "xor_key" "${result#KEY:}"
                local data="${result#*DATA:}"
                echo "$data" | grep -qiE 'flag|ctf|ncse|pico' && emit "decoded" "XOR decoded: $data"
            }
        done <<< "$targets"
    fi

    export XOR_FILE="$f"
    local raw_result=$(python3 -c "
import os, sys
with open(os.environ['XOR_FILE'], 'rb') as f:
    data = f.read(256)
if len(data) < 2: sys.exit(0)
kw = [b'flag', b'ctf', b'ncse', b'pico', b'secret', b'key', b'FLAG', b'CTF', b'CTF{', b'FLAG{']
for k in range(256):
    d = bytes(b ^ k for b in data[:64])
    for w in kw:
        if w in d:
            printable = ''.join(chr(b) if 32 <= b < 127 else '.' for b in d)
            print(f'KEY:0x{k:02x} DATA:{printable}')
            sys.exit(0)
" 2>/dev/null)
    unset XOR_FILE
    if [ -n "$raw_result" ]; then
        emit "xor_key" "Raw XOR: ${raw_result#KEY:}"
        local raw_data="${raw_result#*DATA:}"
        echo "$raw_data" | grep -qiE 'flag|ctf|ncse|pico' && emit "decoded" "XOR decoded: $raw_data"
    else
        info "No XOR key found"
    fi
}
