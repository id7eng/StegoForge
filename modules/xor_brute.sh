MD_NAME="XOR Brute"
MD_DESC="Single-byte XOR brute-force on file/strings"
MD_TYPES="*"
MD_DEPS="python3"
MD_PRIORITY=80
MD_PRODUCES="xor_key decoded"

xor_bruteforce_string() {
    local s="$1"
    local ks="${2:-0}" ke="${3:-255}"
    [ ${#s} -lt 4 ] && return 1
    local result=$(XOR_BF_STR="$s" XOR_BF_KS="$ks" XOR_BF_KE="$ke" python3 -c "
import os, sys
s = os.environ['XOR_BF_STR']
kw = ['picoCTF{','flag{','CTF{','HTB{','THM{','FLAG{','NCSE{','shellctf{','hacker101{','flag','ctf','secret','key','password','FLAG','CTF','NCSE','PICO']
for k in range(int(os.environ['XOR_BF_KS']), int(os.environ['XOR_BF_KE']) + 1):
    d = ''.join(chr(b ^ k) for b in s.encode())
    for w in kw:
        if w in d:
            print(d)
            sys.exit(0)
" 2>/dev/null)
    [ -z "$result" ] && return 1
    echo "$result"
}

analyze_xor_brute() {
    local f="$1"
    header "XOR Brute" "Single-byte XOR key search"

    local targets=$(strings "$f" 2>/dev/null | grep -oE '[A-Za-z0-9+/=]{10,60}' | head -20)
    [ -z "$targets" ] && targets=$(strings "$f" 2>/dev/null | grep -oE '[!-~]{10,60}' | head -10)

    if [ -n "$targets" ]; then
        while IFS= read -r s; do
            local result=$(xor_bruteforce_string "$s" 0 255)
            [ -n "$result" ] && {
                emit_xor_key "Key found for: ${result:0:40}..."
                echo "$result" | grep -qiE 'flag|ctf|ncse|pico' && emit_finding "decoded" "XOR decoded: $result"
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
        emit_xor_key "Raw XOR: ${raw_result#KEY:}"
        local raw_data="${raw_result#*DATA:}"
        echo "$raw_data" | grep -qiE 'flag|ctf|ncse|pico' && emit_finding "decoded" "XOR decoded: $raw_data"
    else
        info "No XOR key found"
    fi
}
