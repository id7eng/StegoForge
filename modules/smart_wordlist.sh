MD_NAME="Smart Wordlist"
MD_DESC="Scored multi-layer password generator from file context + configs"
MD_TYPES="*"
MD_DEPS=""
MD_PRIORITY=5
MD_PRODUCES="smart_wordlist"

PASS_DIR="${CONFIG_DIR}"

get_weight() {
    local word="$1" default="${2:-50}"
    local line
    line=$(grep -m1 -i "^[0-9]* $word$" "$wl_file" 2>/dev/null || true)
    if [ -n "$line" ]; then
        echo "$line" | awk '{print $1}'
    else
        echo "$default"
    fi
}

gen_variations() {
    local base="$1" weight="$2"
    [ ${#base} -lt 2 ] && return
    local lower=$(echo "$base" | tr '[:upper:]' '[:lower:]')
    local upper=$(echo "$base" | tr '[:lower:]' '[:upper:]')
    local cap=$(echo "${base:0:1}" | tr '[:lower:]' '[:upper:]')${base:1}
    echo "$weight $lower"
    [ "$lower" != "$cap" ] && echo "$((weight-2)) $cap"
    [ "$lower" != "$upper" ] && echo "$((weight-5)) $upper"
    echo "$((weight-3)) ${lower}123"
    echo "$((weight-4)) ${lower}2026"
    echo "$((weight-4)) ${lower}2025"
    echo "$((weight-4)) ${lower}2024"
    echo "$((weight-5)) ${lower}!"
    echo "$((weight-5)) ${lower}@"
    echo "$((weight-6)) ${lower}1"
    echo "$((weight-6)) ${lower}123456"
}

gen_exif_variations() {
    local raw="$1"
    [ -z "$raw" ] && return
    local clean=$(echo "$raw" | grep -oE '[A-Za-z]{2,}' | head -1)
    [ -z "$clean" ] && return
    gen_variations "$clean" 93
}

analyze_smart_wordlist() {
    local f="$1"
    header "Smart Wordlist" "Scored Multi-Layer Password Generator"

    local wl_out="${OUTDIR}/.smart_wordlist"
    : > "$wl_out"
    local tmp_wl=$(mktemp)
    : > "$tmp_wl"

    # ── Layer 1: Filename ──
    local fname=$(basename "$f")
    local fname_noext=$(echo "$fname" | sed 's/\.[^.]*$//')
    gen_variations "$fname_noext" 98 >> "$tmp_wl"
    [ "$fname_noext" != "$fname" ] && gen_variations "$fname" 90 >> "$tmp_wl"

    # ── Layer 2: EXIF / Metadata fields ──
    if command -v exiftool &>/dev/null; then
        local exif_data
        exif_data=$(timeout 5 exiftool "$f" 2>/dev/null)
        if [ -n "$exif_data" ]; then
            while IFS= read -r tag; do
                local val=$(echo "$tag" | sed 's/.*: *//' | grep -oE '[A-Za-z]{2,}' | head -1)
                [ -n "$val" ] && gen_variations "$val" 93 >> "$tmp_wl"
            done < <(echo "$exif_data" | grep -iE '^(Author|Artist|Creator|Project|Model|GPS|Comment|Description|Company|Software|XMP|Owner|Host|URL|User)' 2>/dev/null | head -15)
        fi
    fi

    # ── Layer 3: Strings (extract base words) ──
    local size=$(stat -c%s "$f" 2>/dev/null || echo 0)
    if [ "$size" -lt 10485760 ] && [ "$size" -gt 0 ]; then
        local str_out=$(LC_ALL=C strings "$f" 2>/dev/null | tr -d '\0')
        while IFS= read -r word; do
            [ ${#word} -lt 4 ] && continue
            echo "$((60 - ${#word})) $word"
        done < <(echo "$str_out" | grep -oE '[A-Za-z0-9_]{4,20}' | sort -u | head -200)
        while IFS= read -r match; do
            local val=$(echo "$match" | sed 's/.*[:=] *//i')
            [ -n "$val" ] && echo "90 $val"
        done < <(echo "$str_out" | grep -oiE '(password|pass|key|secret) *[:=] *[A-Za-z0-9_!@#$%^&*]{4,}' | head -20)
    fi

    # ── Layer 4: Knowledge Base passwords ──
    local kb_db="${KNOWLEDGE_DIR}/knowledge.db"
    if [ -f "$kb_db" ]; then
        local kb_passwords=$(sqlite3 -separator '|' "$kb_db" "SELECT value, confidence FROM knowledge WHERE knowledge_type='password' AND value != '' GROUP BY value ORDER BY confidence DESC LIMIT 50" 2>/dev/null)
        if [ -n "$kb_passwords" ]; then
            while IFS='|' read -r value conf; do
                [ -z "$value" ] && continue
                local weight=$(echo "$conf * 100 / 1" | bc 2>/dev/null || echo 70)
                echo "$weight $value" >> "$tmp_wl"
                gen_variations "$value" "$weight" >> "$tmp_wl"
            done <<< "$kb_passwords"
        fi
    fi

    # ── Layer 5: Load config files ──

    local gen_file="${PASS_DIR}/passwords_generated.conf"
    [ ! -f "$gen_file" ] && touch "$gen_file"

    for cfg in "$PASS_DIR/passwords.conf" "$gen_file"; do
        [ -f "$cfg" ] && cat "$cfg" >> "$tmp_wl"
    done

    # ── Sort by weight descending, deduplicate, write output ──
    sort -t' ' -k1 -rn "$tmp_wl" 2>/dev/null | awk '!seen[$2]++' > "$wl_out"

    local count=$(wc -l < "$wl_out")
    if [ "$count" -gt 1 ]; then
        SMART_WL="$wl_out"
        info "Generated $count scored passwords"
    else
        rm -f "$wl_out" 2>/dev/null
        SMART_WL=""
    fi

    rm -f "$tmp_wl" 2>/dev/null
}
