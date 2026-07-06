MD_NAME="Zsteg"
MD_DESC="LSB detection for PNG/BMP with auto-fallback to cross-channel/conditional LSB"
MD_TYPES="png bmp"
MD_DEPS="zsteg"
MD_PRIORITY=30
MD_PRODUCES="lsb_data flag"

analyze_zsteg() {
    local f="$1"
    header "Zsteg" "LSB Analysis"

    local zsteg_found_flag=false

    if command -v zsteg &>/dev/null; then
        local zsteg_opts=""
        $VERBOSE && zsteg_opts="-a"
        log_cmd zsteg $zsteg_opts "$f"
        local zsteg_out
        zsteg_out=$(zsteg $zsteg_opts "$f" 2>/dev/null)
        while IFS= read -r l; do
            l=$(echo "$l" | tr -d '\r')
            echo "$l" | grep -qE '\.\. *$' && continue
            echo "$l" | grep -q '\.\. file:' && continue
            local txt=$(echo "$l" | sed 's/.*\.\. *text: *"//; s/"$//')
            if [ -n "$txt" ]; then
                local flag=$(extract_flags "$txt" | head -1)
                if [ -n "$flag" ]; then
                    emit_flag "$flag (zsteg)"
                    zsteg_found_flag=true
                    continue
                fi
            fi
            local b64=$(echo "$l" | grep -oE '[A-Za-z0-9+/]{30,}={0,2}' | head -1)
            if [ -n "$b64" ]; then
                local d=$(echo "$b64" | base64 -d 2>/dev/null)
                if [ -n "$d" ] && echo "$d" | grep -qiE "flag|ctf|ncse|pico|secret" 2>/dev/null; then
                    emit_flag "$d"
                    zsteg_found_flag=true
                    continue
                fi
            fi
        done <<< "$zsteg_out"
    else
        info "zsteg not installed"; return
    fi

    # ─── Fallback: Cross-channel LSB ───
    if ! $zsteg_found_flag; then
        if command -v analyze_cross_lsb &>/dev/null; then
            info "zsteg found nothing — trying cross-channel LSB..."
            analyze_cross_lsb "$f"
        fi

        # ─── Fallback: Conditional bit plane (near-black) ───
        if [ -n "${OUTDIR:-}" ]; then
            local pre_count=${#EMITTED[@]}
            local flag_before=false
            for ev in "${EMITTED[@]}"; do echo "$ev" | grep -q "^flag:" && flag_before=true; done

            if ! $flag_before; then
                info "Trying conditional bit plane (near-black filter)..."
                BP_CONDITION_ENABLED=1 BP_TARGET_R=0 BP_TARGET_G=0 BP_TARGET_B=0 BP_TOLERANCE=30 \
                    analyze_bit_plane "$f"

                local flag_still=false
                for ev in "${EMITTED[@]}"; do echo "$ev" | grep -q "^flag:" && flag_still=true; done
                if ! $flag_still; then
                    info "Trying conditional bit plane (near-white filter)..."
                    BP_CONDITION_ENABLED=1 BP_TARGET_R=255 BP_TARGET_G=255 BP_TARGET_B=255 BP_TOLERANCE=30 \
                        analyze_bit_plane "$f"
                fi
            fi
        fi
    fi
}
