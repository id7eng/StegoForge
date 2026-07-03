MD_NAME="ZIP Brute"
MD_DESC="Crack password-protected ZIP archives"
MD_TYPES="zip"
MD_DEPS="unzip"
MD_PRIORITY=55
MD_PRODUCES="zip_password extracted"
MD_TRIGGERS="embedded_file"

analyze_zip_brute() {
    local f="$1" wl="$2"
    header "ZIP Brute" "Password-Protected Archive Cracking"

    local ext_dir="${OUTDIR}/carved/zip_extracted"
    mkdir -p "$ext_dir"

    # Try without password first
    if unzip -o "$f" -d "$ext_dir" &>/dev/null 2>&1; then
        info "ZIP extracted (no password)"
        for ext_file in "$ext_dir"/*; do
            [ -f "$ext_file" ] && {
                local content=$(strings "$ext_file" 2>/dev/null | head -5)
                [ -n "$content" ] && emit "extracted" "$content"
            }
        done
        return
    fi

    # Password protected — brute-force
    local pwlist="$wl"
    [ -z "$pwlist" ] || [ ! -f "$pwlist" ] && pwlist="$SMART_WL"
    if [ -z "$pwlist" ] || [ ! -f "$pwlist" ]; then
        [ -f "${CONFIG_DIR}/passwords.conf" ] && pwlist="${CONFIG_DIR}/passwords.conf"
    fi
    if [ -z "$pwlist" ] || [ ! -f "$pwlist" ]; then
        pwlist=$(mktemp)
        printf "password\n123456\n1234\nsecret\nflag\nstego\nctf\nadmin\nroot\ntest\n" > "$pwlist"
        local cleanup_pw=true
    fi

    info "Brute-forcing passwords..."

    # Use fcrackzip if available (much faster)
    if command -v fcrackzip &>/dev/null; then
        local fcrack_out=$(fcrackzip -v -D -p "$pwlist" "$f" 2>/dev/null)
        local fpass=$(echo "$fcrack_out" | grep -oP 'possible pw found: \K\S+' 2>/dev/null)
        if [ -n "$fpass" ]; then
            emit "zip_password" "ZIP password: $fpass"
            unzip -o -P "$fpass" "$f" -d "$ext_dir" &>/dev/null 2>&1
            for ext_file in "$ext_dir"/*; do
                [ -f "$ext_file" ] && {
                    local content=$(strings "$ext_file" 2>/dev/null | head -5)
                    [ -n "$content" ] && emit "extracted" "$content"
                }
            done
            [ "$cleanup_pw" = true ] && rm -f "$pwlist"
            return
        fi
    else
        # Fallback to unzip loop
        while IFS= read -r p; do
            [ -z "$p" ] && continue
            rm -rf "$ext_dir"/* 2>/dev/null
            if unzip -o -P "$p" "$f" -d "$ext_dir" &>/dev/null 2>&1; then
                emit "zip_password" "ZIP password: $p"
                for ext_file in "$ext_dir"/*; do
                    [ -f "$ext_file" ] && {
                        local content=$(strings "$ext_file" 2>/dev/null | head -5)
                        [ -n "$content" ] && emit "extracted" "$content"
                    }
                done
                [ "$cleanup_pw" = true ] && rm -f "$pwlist"
                return
            fi
        done < "$pwlist"
    fi

    [ "$cleanup_pw" = true ] && rm -f "$pwlist"
    info "No ZIP password found"
}
