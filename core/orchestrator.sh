# ─────────────────────────────────────────────
# Orchestrator — module loading, workflow,
# pipeline processing, and file analysis
# ─────────────────────────────────────────────

PIPELINE_CONF="${CONFIG_DIR}/pipeline.conf"

load_pipeline_rules() {
    PIPELINE_RULES=()
    [ -f "$PIPELINE_CONF" ] || return
    while IFS='|' read -r etype tmod; do
        [[ "$etype" =~ ^#.*$ ]] || [ -z "$etype" ] && continue
        etype=$(echo "$etype" | xargs)
        tmod=$(echo "$tmod" | xargs)
        [ -n "$etype" ] && [ -n "$tmod" ] && PIPELINE_RULES+=("$etype|$tmod")
    done < "$PIPELINE_CONF"
}

PIPELINE_SEEN=()
process_pipeline() {
    [ -z "${STEGOFORGE_TEST:-}" ] || return
    local f="$1" wl="$2"
    local new_items=()
    for ev in "${EMITTED[@]}"; do
        local ev_type="${ev%%:*}"
        local ev_data="${ev#*:}"
        [ "$ev_type" = "$ev" ] && continue
        local seen=false
        for s in "${PIPELINE_SEEN[@]}"; do
            [ "$s" = "$ev" ] && { seen=true; break; }
        done
        $seen && continue
        PIPELINE_SEEN+=("$ev")
        new_items+=("$ev")
    done
    for ev in "${new_items[@]}"; do
        local ev_type="${ev%%:*}"
        local ev_data="${ev#*:}"
        for rule in "${PIPELINE_RULES[@]}"; do
            local rule_type="${rule%%|*}"
            local rule_mod="${rule##*|}"
            [ "$rule_type" != "$ev_type" ] && continue
            local pipe_file="${OUTDIR}/pipeline/${ev_type}_$$.txt"
            mkdir -p "${OUTDIR}/pipeline"
            local clean_data="$ev_data"
            clean_data=$(echo "$clean_data" | sed 's/^Base64: *//; s/^Flag: *//; s/^FLAG: *//; s/^Keyword: *//')
            echo "$clean_data" | grep -qE '^[A-Za-z0-9+/]{10,}={0,2}$' && {
                local decoded=$(echo "$clean_data" | base64 -d 2>/dev/null)
                [ -n "$decoded" ] && clean_data="$decoded"
            }
            echo "$clean_data" > "$pipe_file"
            if [ -f "$pipe_file" ]; then
                $VERBOSE && echo -e "\n${C}── ${W}Pipeline: $ev_type → ${MODULE_DISPLAY[$rule_mod]:-$rule_mod}${N}${C} ──${N}"
                if command -v "analyze_$rule_mod" &>/dev/null 2>&1; then
                    "analyze_$rule_mod" "$pipe_file" "$wl"
                    [[ " ${run_done[@]} " =~ " $rule_mod " ]] || run_done+=("$rule_mod")
                fi
            fi
        done

        # KB-guided pipeline: query knowledge base for relevant tools
        if [ -f "${KNOWLEDGE_DIR}/knowledge.db" ]; then
            local kb_ftype=$(echo "$ev_type" | tr '[:upper:]' '[:lower:]')
            local kb_tools=$(sqlite3 -separator '|' "${KNOWLEDGE_DIR}/knowledge.db" "SELECT DISTINCT value FROM knowledge WHERE knowledge_type='tool' AND (key LIKE '%$kb_ftype%' OR value LIKE '%$kb_ftype%') LIMIT 5" 2>/dev/null)
            if [ -n "$kb_tools" ]; then
                while IFS= read -r kb_tool; do
                    [ -z "$kb_tool" ] && continue
                    local kb_mod=$(echo "$kb_tool" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9_]//g')
                    if command -v "analyze_$kb_mod" &>/dev/null 2>&1; then
                        [[ " ${run_done[@]} " =~ " $kb_mod " ]] && continue
                        $VERBOSE && echo -e "\n${C}── ${W}KB Pipeline: $ev_type → ${MODULE_DISPLAY[$kb_mod]:-$kb_mod}${N}${C} ──${N}"
                        local kb_pipe_file="${OUTDIR}/pipeline/kb_${ev_type}_$$.txt"
                        echo "$clean_data" > "$kb_pipe_file"
                        "analyze_$kb_mod" "$kb_pipe_file" "$wl"
                        [[ " ${run_done[@]} " =~ " $kb_mod " ]] || run_done+=("$kb_mod")
                    fi
                done <<< "$kb_tools"
            fi
        fi
    done
}

load_modules() {
    MODULE_NAMES=()
    MODULE_PRIORITY_ORDER=()
    for mod in "$MODULES_DIR"/*.sh; do
        [ -f "$mod" ] || continue
        local base=$(basename "$mod" .sh)
        MODULE_NAMES+=("$base")
        source "$mod"
        MODULE_DISPLAY["$base"]="${MD_NAME:-$base}"
        MODULE_TYPES["$base"]="${MD_TYPES:-*}"
        MODULE_DEPS["$base"]="${MD_DEPS:-}"
        MODULE_PRIORITY["$base"]="${MD_PRIORITY:-50}"
        MODULE_PRODUCES["$base"]="${MD_PRODUCES:-}"
        MODULE_TRIGGERS["$base"]="${MD_TRIGGERS:-}"
    done

    MODULE_PRIORITY_ORDER=($(
        for name in "${MODULE_NAMES[@]}"; do
            echo "${MODULE_PRIORITY[$name]}:$name"
        done | sort -t: -k1 -n | cut -d: -f2
    ))
}

run_workflow() {
    local f="$1" wl="$2"
    local -a run_queue run_done

    run_queue=("${MODULE_PRIORITY_ORDER[@]}")
    run_done=()

    local max_iter=50
    while [ ${#run_queue[@]} -gt 0 ] && [ $max_iter -gt 0 ]; do
        local name="${run_queue[0]}"
        run_queue=("${run_queue[@]:1}")

        [[ " ${run_done[@]} " =~ " $name " ]] && continue
        run_done+=("$name")

        local ftype_raw=$(get_file_type "$f")
        local types="${MODULE_TYPES[$name]:-}"

        local should_run=false
        [[ "$types" == "*" ]] && should_run=true || {
            local ftype_first=$(echo "$ftype_raw" | awk '{print tolower($1)}')
            for t in $types; do
                if [ "$t" = "data" ]; then
                    [ "$ftype_first" = "data" ] && { should_run=true; break; }
                else
                    echo "$ftype_raw" | grep -qw "$t" 2>/dev/null && { should_run=true; break; }
                fi
            done
        }

        if $should_run; then
            if command -v "analyze_$name" &>/dev/null 2>&1; then
                CURRENT_MODULE="$name"
                "analyze_$name" "$f" "$wl"
                local _mod_exit=$?
                CURRENT_MODULE=""
                lp_track_module_run "$name"
                if [ -f "${KNOWLEDGE_DIR}/knowledge.db" ] && command -v db_stats_update &>/dev/null 2>&1; then
                    local _kb_ftype=$(echo "$ftype_raw" | awk '{print tolower($1)}')
                    local _kb_ok=0; [ "$_mod_exit" -eq 0 ] && _kb_ok=1
                    db_stats_update "$_kb_ftype" "$name" "$name" "$_kb_ok"
                fi
            fi

            process_pipeline "$f" "$wl"

            local emitted_combined=""
            for ev in "${EMITTED[@]}"; do
                emitted_combined+="$ev"$'\n'
            done
            [ -n "$emitted_combined" ] && get_conditional_boost "$name" "$emitted_combined"

            MODULE_PRIORITY_ORDER=($(
                for n in "${MODULE_NAMES[@]}"; do
                    echo "${MODULE_PRIORITY[$n]:-50}:$n"
                done | sort -t: -k1 -n | cut -d: -f2
            ))
            local -a tmp_rq=()
            for qn in "${MODULE_PRIORITY_ORDER[@]}"; do
                local _skip=false
                for dn in "${run_done[@]}"; do [ "$qn" = "$dn" ] && { _skip=true; break; }; done
                $_skip || tmp_rq+=("$qn")
            done
            run_queue=("${tmp_rq[@]}")

            for ev in "${EMITTED[@]}"; do
                local ev_type="${ev%%:*}"
                local triggered=()
                for n in "${run_queue[@]}"; do
                    [ -z "$n" ] && continue
                    local triggers="${MODULE_TRIGGERS[$n]:-}"
                    if [[ " $triggers " =~ " $ev_type " ]]; then
                        [[ " ${run_done[@]} " =~ " $n " ]] && continue
                        local already=false
                        for q in "${run_queue[@]}" "${triggered[@]}"; do
                            [ "$q" = "$n" ] && { already=true; break; }
                        done
                        $already || triggered+=("$n")
                    fi
                done
                run_queue=("${triggered[@]}" "${run_queue[@]}")
            done

            de_evaluate "$ftype_raw" "$name"
            for ((_de_i=${#_DECIDE_PRIORITIZE[@]}-1; _de_i>=0; _de_i--)); do
                local _de_mod="${_DECIDE_PRIORITIZE[$_de_i]}"
                [[ " ${run_done[@]} " =~ " $_de_mod " ]] && continue
                local _de_in_queue=false
                for _de_q in "${run_queue[@]}"; do
                    [ "$_de_q" = "$_de_mod" ] && { _de_in_queue=true; break; }
                done
                $_de_in_queue || run_queue=("$_de_mod" "${run_queue[@]}")
            done
            for _de_mod in "${_DECIDE_SKIP[@]}"; do
                [[ " ${run_done[@]} " =~ " $_de_mod " ]] || run_done+=("$_de_mod")
            done
            $_DECIDE_STOP && break
        fi

        : $((max_iter--))
    done
}

analyze_file() {
    local f="$1" wl="$2"

    if [[ "$f" == *.gz ]] || file -b "$f" 2>/dev/null | grep -qi "gzip compressed"; then
        local decomp="${OUTDIR}/carved/$(basename "$f" .gz)"
        gzip -dc "$f" > "$decomp" 2>/dev/null
        [ -f "$decomp" ] && f="$decomp"
    fi

    local ftype_raw=$(get_file_type "$f")

    local ftype_first=$(echo "$ftype_raw" | awk '{print tolower($1)}')
    get_priority_boosted_modules "$ftype_first"

    lp_init_session

    _DECIDE_KB_HINT=()
    if [ -f "${KNOWLEDGE_DIR}/knowledge.db" ]; then
        source "${KNOWLEDGE_DIR}/db.sh" 2>/dev/null
        source "${KNOWLEDGE_DIR}/inference.sh" 2>/dev/null
        inference_init 2>/dev/null
        $VERBOSE && [ "${VERBOSE_CMD:-false}" = false ] && db_log "KB" "Knowledge base found, adjusting priorities..."
        local _kb_before=$(for n in "${MODULE_NAMES[@]}"; do echo "${MODULE_PRIORITY[$n]:-50}:$n"; done | sort)
        inference_boost_priorities "$ftype_raw" 2>/dev/null
        local _kb_after=$(for n in "${MODULE_NAMES[@]}"; do echo "${MODULE_PRIORITY[$n]:-50}:$n"; done | sort)
    fi

    MODULE_PRIORITY_ORDER=($(
        for name in "${MODULE_NAMES[@]}"; do
            echo "${MODULE_PRIORITY[$name]:-50}:$name"
        done | sort -t: -k1 -n | cut -d: -f2
    ))

    if $READONLY; then
        local tmpdir="/tmp/stegoforge_ro_$$"
        mkdir -p "$tmpdir"
        cp "$f" "$tmpdir/"
        f="$tmpdir/$(basename "$f")"
    fi

    if [ "$QUIET" = true ]; then exec 3>&1; exec 1>/dev/null; fi

    echo -e "\n${C}══════════════════════════════════════════════${N}"
    echo -e "${W}  File:${N} $f"
    echo -e "${W}  Type:${N} ${ftype_raw%%,*}"
    echo -e "${C}══════════════════════════════════════════════${N}"

    header "Info" "File Info"
    echo "  MD5:    $(md5sum "$f" | cut -d' ' -f1)"
    echo "  SHA256: $(sha256sum "$f" | cut -d' ' -f1)"
    echo "  Size:   $(numfmt --to=iec $(( $(stat -c%s "$f" 2>/dev/null) )) 2>/dev/null || du -h "$f" | cut -f1)"

    if [ -f "${KNOWLEDGE_DIR}/knowledge.db" ]; then
        local kb_suggestions=$(inference_analyze "$f" "$ftype_raw" 2>/dev/null)
        local kb_reasoning=$(echo "$kb_suggestions" | grep "^REASONING:" | sed 's/^REASONING://')
        if [ -n "$kb_reasoning" ] && $VERBOSE; then
            echo ""
            echo -e "${BOLD}📚 Knowledge Base Suggestions:${N}"
            echo "$kb_reasoning"
        fi
        [ -f "${OUTDIR}/.kb_evidence" ] && cp "${OUTDIR}/.kb_evidence" "${OUTDIR}/reports/kb_evidence.log" 2>/dev/null
    fi

    lp_track_file_analysis
    lp_file_update "$f"
    run_workflow "$f" "$wl"

    if [ -n "$ANALYZE_THIS" ] && [ -f "$ANALYZE_THIS" ]; then
        local repaired="$ANALYZE_THIS"
        ANALYZE_THIS=""
        run_workflow "$repaired" "$wl"
    fi

    [ "$QUIET" = true ] && exec 1>&3 3>&-
}
