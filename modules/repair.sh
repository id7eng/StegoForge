MD_NAME="Repair"
MD_DESC="Fix corrupted/missing magic bytes"
MD_TYPES="data"
MD_DEPS="file xxd"
MD_PRIORITY=1
MD_PRODUCES="repaired_file"

analyze_repair() {
    local f="$1"
    local repaired="$f.repaired"
    local raw_hex=$(xxd -l 16 -p "$f" 2>/dev/null)
    local raw_last=$(xxd -s -4 -p "$f" 2>/dev/null)
    local first_two=$(echo "$raw_hex" | cut -c1-4)
    local guess=""

    case "$raw_last" in
        ffd9) guess="jpeg" ;;
        6082|ae42*|49454e44*) guess="png" ;;
        003b) guess="gif" ;;
    esac
    [ -z "$guess" ] && strings "$f" 2>/dev/null | grep -q 'JFIF' && guess="jpeg"
    [ -z "$guess" ] && strings "$f" 2>/dev/null | grep -q 'IHDR' && guess="png"
    [ -z "$guess" ] && strings "$f" 2>/dev/null | grep -q 'GIF8' && guess="gif"
    [ -z "$guess" ] && strings "$f" 2>/dev/null | grep -q '%PDF' && guess="pdf"
    [ -z "$guess" ] && head -c 100 "$f" 2>/dev/null | grep -q 'PK' && guess="zip"

    if head -1 "$f" 2>/dev/null | grep -qiE '^[0-9a-f]{2}([-\s:]?[0-9a-f]{2})+'; then
        xxd -r -p <(sed 's/[^0-9a-fA-F]//g' "$f") "$repaired" 2>/dev/null
        file "$repaired" 2>/dev/null | grep -qiE 'jpeg|png|gif|zip|pdf|bmp|elf|exe' && {
            emit "repaired_file" "Repaired hex dump → $(file -b "$repaired")"
            cp "$repaired" "${OUTDIR}/repaired/" 2>/dev/null
            ANALYZE_THIS="$repaired"
            return
        }
    fi

    local offset=0
    [ "$first_two" = "5c78" ] && offset=2

    case "$guess" in
        jpeg) (printf '\xff\xd8'; tail -c +$((offset+1)) "$f") > "$repaired" 2>/dev/null ;;
        png)  (printf '\x89\x50\x4e\x47\x0d\x0a\x1a\x0a'; tail -c +$((offset+1)) "$f") > "$repaired" 2>/dev/null ;;
        gif)  (printf 'GIF89a'; tail -c +$((offset+1)) "$f") > "$repaired" 2>/dev/null ;;
        pdf)  (printf '%%PDF-1.4\n'; tail -c +$((offset+1)) "$f") > "$repaired" 2>/dev/null ;;
        zip)  (printf 'PK\x03\x04'; tail -c +$((offset+1)) "$f") > "$repaired" 2>/dev/null ;;
        *)    return ;;
    esac

    if file "$repaired" 2>/dev/null | grep -qiE "$guess|image|archive|document"; then
        local newtype=$(file -b "$repaired")
        emit "repaired_file" "Repaired → $newtype"
        cp "$repaired" "${OUTDIR}/repaired/" 2>/dev/null
        ANALYZE_THIS="$repaired"
    else
        rm -f "$repaired" 2>/dev/null
    fi
}
