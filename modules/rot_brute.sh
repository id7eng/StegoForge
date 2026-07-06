MD_NAME="ROT Brute"
MD_DESC="Brute-force Caesar/ROT cipher (ROT1-25) on extracted strings"
MD_TYPES="*"
MD_DEPS="python3"
MD_PRIORITY=11
MD_PRODUCES="rot_decoded flag"

analyze_rot_brute() {
    local f="$1"
    header "ROT Brute" "Caesar Cipher Brute Force"

    local str_out=$(LC_ALL=C strings "$f" 2>/dev/null | tr -d '\0')

    # Try ROT1-25 on each line longer than 8 chars
    while IFS= read -r line; do
        [ "${#line}" -lt 8 ] && continue
        run_cmd python3 -c "
import sys
line = sys.argv[1]
for shift in range(1, 26):
    decoded = ''.join(
        chr((ord(c) - 65 + shift) % 26 + 65) if 'A' <= c <= 'Z' else
        chr((ord(c) - 97 + shift) % 26 + 97) if 'a' <= c <= 'z' else c
        for c in line
    )
    if any(p in decoded for p in ['picoCTF{', 'HTB{', 'THM{', 'FLAG{', 'flag{', 'CTF{']):
        print(decoded)
        sys.exit(0)
" "$line" 2>/dev/null
    done < <(echo "$str_out") > /tmp/rot_candidates.txt
    while read candidate; do
        emit "rot_decoded" "ROT decoded: $candidate"
        for p in "${FLAG_PATTERNS[@]}"; do
            local match=$(echo "$candidate" | grep -oP "$p" 2>/dev/null)
            [ -n "$match" ] && emit "flag" "$match"
        done
    done < /tmp/rot_candidates.txt
    rm -f /tmp/rot_candidates.txt
}
