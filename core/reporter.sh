# ─────────────────────────────────────────────
# Reporter — generates final analysis output
# Supports quiet, JSON, summary, and full modes
# ─────────────────────────────────────────────

generate_report() {
    local header_msg="$1"
    local -A seen_flag
    local flags_list=()
    local partial_flags=()

    for finding in "${FINDINGS[@]}"; do
        for pattern in "${FLAG_PATTERNS[@]}"; do
            local match=$(echo "$finding" | grep -oP "$pattern" 2>/dev/null | head -1)
            if [ -n "$match" ]; then
                local dup=false
                for j in "${!flags_list[@]}"; do
                    if [[ "${flags_list[$j]}" == *"$match"* ]]; then
                        dup=true; break
                    elif [[ "$match" == *"${flags_list[$j]}"* ]]; then
                        unset flags_list[$j]
                        flags_list=("${flags_list[@]}")
                    fi
                done
                $dup || flags_list+=("$match")
                break
            fi
        done
    done

    for finding in "${FINDINGS[@]}"; do
        local tail=$(echo "$finding" | grep -oP '[a-zA-Z0-9_!@#$%^&*()+\-]{6,}\}' 2>/dev/null | head -1)
        if [ -n "$tail" ]; then
            local dup=false
            for p in "${partial_flags[@]}"; do
                [[ "$p" == "$tail" ]] && { dup=true; break; }
            done
            $dup || partial_flags+=("$tail")
        fi
    done

    if $JSON; then
        echo -e '{\n  "file": "'"$TARGET"'",'
        echo -e '  "version": "'"$VERSION"'",'
        echo -e '  "flags": ['"$(printf '"%s",' "${flags_list[@]}" | sed 's/,$//')"'],'
        echo -e '  "count": '${#flags_list[@]}','
        echo -e '  "findings": '${#FINDINGS[@]}','
        echo -e '  "output": "'"$OUTDIR"'",'
        echo -e '  "status": "'$([ ${#flags_list[@]} -gt 0 ] && echo "found" || echo "not_found")'"\n}'
        return
    fi

    if $SUMMARY; then
        local fname=$(basename "$TARGET")
        if [ ${#flags_list[@]} -gt 0 ]; then
            for flag in "${flags_list[@]}"; do
                echo -e "${W}$fname${N} → ${LG}$flag${N}"
            done
        elif [ ${#partial_flags[@]} -gt 0 ]; then
            for p in "${partial_flags[@]}"; do
                echo -e "${W}$fname${N} → ${Y}Partial: $p${N}"
            done
        else
            echo -e "${W}$fname${N} → ${Y}No flag${N}"
        fi
        return
    fi

    if [ "$QUIET" = true ]; then
        if [ ${#flags_list[@]} -gt 0 ]; then
            for flag in "${flags_list[@]}"; do
                echo -e "${W}Flag:${N} ${LG}$flag${N}"
            done
        elif [ ${#partial_flags[@]} -gt 0 ]; then
            echo -e "  ${Y}Partial flag(s):${N}"
            for p in "${partial_flags[@]}"; do
                echo -e "    ${Y}$p${N}"
            done
        else
            echo -e "  ${Y}No flag found${N}"
        fi
        return
    fi

    echo -e "\n${C}╔══════════════════════════════════════════════╗${N}"
    echo -e "${C}║${W}  Analysis Complete${C}${N}"
    echo -e "${C}║${N}  $header_msg"
    echo -e "${C}║${N}"
    if [ ${#FINDINGS[@]} -gt 0 ]; then
        echo -e "${C}║${W}  Findings (${#FINDINGS[@]}):${N}"
        for f in "${FINDINGS[@]}"; do echo -e "${C}║${G}  OK${N} $f"; done
    else
        echo -e "${C}║  ${Y}No suspicious findings${N}"
    fi
    if [ ${#flags_list[@]} -gt 0 ]; then
        echo -e "${C}║${N}"
        echo -e "${C}║${G}  Flag(s):${N}"
        for flag in "${flags_list[@]}"; do echo -e "${C}║${LG}  $flag${N}"; done
    elif [ ${#partial_flags[@]} -gt 0 ]; then
        echo -e "${C}║${N}"
        echo -e "${C}║${Y}  Partial flag(s):${N}"
        for p in "${partial_flags[@]}"; do echo -e "${C}║${Y}  $p${N}"; done
    fi
    echo -e "${C}║${N}"
    echo -e "${C}║${N}  Output: ${B}$OUTDIR${N}"
    echo -e "${C}╚══════════════════════════════════════════════╝${N}"
}
