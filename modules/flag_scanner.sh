MD_NAME="Flag Scanner"
MD_DESC="Catch-all scanner for flag patterns in all extracted data"
MD_TYPES="*"
MD_DEPS=""
MD_PRIORITY=99
MD_PRODUCES="flag"

analyze_flag_scanner() {
    local f="$1"
    header "Flag Scanner" "Catch-all flag detection"

    local found=0

    while IFS= read -r -d '' file; do
        local base=$(basename "$file")
        local text=$(strings "$file" 2>/dev/null | tr -d '\0')
        [ -z "$text" ] && continue
        local flags=$(extract_flags "$text" 2>/dev/null)
        if [ -n "$flags" ]; then
            while IFS= read -r flag; do
                [ -z "$flag" ] && continue
                local dup=false
                for ev in "${EMITTED[@]}"; do
                    [[ "$ev" == *"$flag"* ]] && { dup=true; break; }
                done
                $dup || {
                    emit_flag "FLAG: $flag ($base)"
                    found=$((found + 1))
                }
            done <<< "$flags"
        fi

        # Try single-byte XOR on obfuscated-looking strings
        local xor_targets=$(echo "$text" | grep -oE '[!-~]{4,50}' | sort -u | head -20)
        if [ -n "$xor_targets" ] && command -v xor_bruteforce_string &>/dev/null; then
            while IFS= read -r s; do
                local xresult=$(xor_bruteforce_string "$s" 1 255)
                if [ -n "$xresult" ]; then
                    local xflag=$(extract_flags "$xresult" 2>/dev/null | head -1)
                    [ -n "$xflag" ] && {
                        local dup=false
                        for ev in "${EMITTED[@]}"; do [[ "$ev" == *"$xflag"* ]] && { dup=true; break; }; done
                        $dup || {
                            emit_flag "FLAG: $xflag (XOR in $base)"
                            found=$((found + 1))
                        }
                    }
                fi
            done <<< "$xor_targets"
        fi
    done < <(find "$OUTDIR" -type f -print0 2>/dev/null)

    [ "$found" -eq 0 ] && info "No additional flags found in output files"
}
