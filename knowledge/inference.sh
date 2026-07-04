# ─────────────────────────────────────────────
# StegoForge Knowledge — Inference Engine
# ─────────────────────────────────────────────
# Uses accumulated knowledge to:
#   - Suggest best tools for a file type
#   - Suggest workflows based on similar cases
#   - Provide evidence for decisions
#   - Adjust module priorities dynamically

INFERENCE_SESSION=""

calc_pct() {
    local conf="$1"
    local int_part="${conf%%.*}"
    local frac_part="${conf#*.}"
    [ "$frac_part" = "$conf" ] && frac_part="0"
    [ -z "$frac_part" ] && frac_part="0"
    while [ ${#frac_part} -lt 2 ]; do frac_part="${frac_part}0"; done
    frac_part="${frac_part:0:2}"
    local result=$((int_part * 100 + ${frac_part:-0}))
    result=$((result > 100 ? 100 : result))
    echo "$result"
}

inference_init() {
    INFERENCE_SESSION="stegoforge_$$_$(date +%s)"
}

inference_analyze() {
    local file_path="$1" ftype="$2"
    [ ! -f "$DB_PATH" ] && { db_log "INFERENCE" "No database yet. Run 'stegoforge knowledge sync' first."; return; }

    # Normalize file type to lowercase base type
    local ftype_norm=$(echo "$ftype" | tr '[:upper:]' '[:lower:]' | awk '{print $1}' | sed 's/,.*//')

    db_log "INFERENCE" "Analyzing: $file_path (type: $ftype_norm)"

    local suggestions=""
    local reasoning=""

    # ─── 1. Best tools from statistics ───
    local best_tools=$(db_stats_best_for "$ftype_norm" 5)
    if [ -n "$best_tools" ]; then
        suggestions+="best_tools|$best_tools"$'\n'
        while IFS='|' read -r tool technique conf count; do
            [ -z "$tool" ] && continue
            local cp=$(calc_pct "$conf")
            reasoning+="  • $tool (technique: $technique) — نجح في $count حالة، بثقة $cp%"$'\n'
        done <<< "$best_tools"
    fi

        # ─── 2. Similar writeups ───
    local similar=$(db_query "SELECT DISTINCT w.challenge_name, w.category, w.url FROM writeups w JOIN knowledge k ON w.id = k.writeup_id WHERE k.knowledge_type='file_type' AND k.key='$ftype_norm' ORDER BY w.fetched_at DESC LIMIT 5")
    if [ -n "$similar" ]; then
        local count=0
        while IFS='|' read -r challenge category url; do
            [ -z "$challenge" ] && continue
            count=$((count + 1))
        done <<< "$similar"
        reasoning+="  • $count حالة مشابهة موجودة في قاعدة المعرفة"$'\n'
    fi

    # ─── 3. Known workflows for this file type ───
    local workflows=$(db_workflows_for_filetype "$ftype" 8)
    if [ -n "$workflows" ]; then
        reasoning+="  • أفضل سير عمل مستخلص من الكتابات:"$'\n'
        while IFS='|' read -r action tool params freq; do
            [ -z "$tool" ] && continue
            reasoning+="    → $tool $params (مذكور في $freq كتابة)"$'\n'
        done <<< "$workflows"
    fi

    # ─── 4. File signatures / indicators ───
    local indicators=$(db_knowledge_by_type "indicator" 5)
    if [ -n "$indicators" ]; then
        reasoning+="  • مؤشرات شائعة لهذا النوع من الملفات:"$'\n'
        while IFS='|' read -r key value conf freq; do
            [ -z "$value" ] && continue
            reasoning+="    - $value (في $freq كتابة)"$'\n'
        done <<< "$indicators"
    fi

    echo "SUGGESTIONS:$suggestions"
    echo "REASONING:$reasoning"
}

inference_suggest_next_step() {
    local file_type="$1" current_tool="$2" result="$3"
    local ftype=$(echo "$file_type" | tr '[:upper:]' '[:lower:]' | awk '{print $1}')

    # Get the most common next tool after current_tool from workflows
    local next_tools=$(db_query "SELECT wf2.tool, COUNT(*) as freq FROM workflows wf1 JOIN workflows wf2 ON wf1.writeup_id = wf2.writeup_id AND wf2.step_order = wf1.step_order + 1 WHERE wf1.tool='$current_tool' AND wf2.tool != '' GROUP BY wf2.tool ORDER BY freq DESC LIMIT 3")

    if [ -n "$next_tools" ]; then
        db_log "INFERENCE" "Next steps based on knowledge:"
        while IFS='|' read -r tool freq; do
            [ -z "$tool" ] && continue
            db_log "INFERENCE" "  → $tool (مذكور في $freq حالة)"
            local evidence_sources=$(db_query "SELECT w.title FROM workflows wf JOIN writeups w ON wf.writeup_id = w.id WHERE wf.tool='$tool' AND w.title != '' LIMIT 3" | paste -sd,)
            echo "NEXT:$tool|$freq|$evidence_sources"
        done <<< "$next_tools"
    fi

    # Also check statistics
    local stats=$(db_stats_best_for "$ftype" 5)
    if [ -n "$stats" ]; then
        while IFS='|' read -r tool technique conf count; do
            [ -z "$tool" ] && continue
            [ "$tool" = "$current_tool" ] && continue
            local cp=$(calc_pct "$conf")
            echo "NEXT:$tool|$technique|$cp% نجاح من $count حالة"
        done <<< "$stats"
    fi
}

inference_boost_priorities() {
    local file_type="$1"
    local ftype=$(echo "$file_type" | tr '[:upper:]' '[:lower:]' | cut -d'/' -f1 | cut -d' ' -f1 | sed 's/,.*//')
    local evidence_file="${OUTDIR}/.kb_evidence"

    db_log "INFERENCE" "Adjusting priorities for: $ftype"
    : > "$evidence_file"

    # Get best tools from knowledge base
    local best=$(db_stats_best_for "$ftype" 10)
    local boost_count=0

    if [ -n "$best" ]; then
        echo "📚 Knowledge Base Evidence" >> "$evidence_file"
        echo "══════════════════════════" >> "$evidence_file"
        echo "" >> "$evidence_file"
        echo "نوع الملف: $ftype" >> "$evidence_file"
        echo "" >> "$evidence_file"
        echo "أفضل الأدوات حسب قاعدة المعرفة:" >> "$evidence_file"

        while IFS='|' read -r tool technique conf count; do
            [ -z "$tool" ] && continue
            local cp=$(calc_pct "$conf")

            # Boost module priority if it exists
            if [ -n "${MODULE_PRIORITY[$tool]:-}" ]; then
                local current="${MODULE_PRIORITY[$tool]}"
                local boost=$(( cp / 10 ))
                [ "$boost" -lt 1 ] && boost=1
                local new=$(( current - boost ))
                [ "$new" -lt 1 ] && new=1
                MODULE_PRIORITY["$tool"]=$new
                MODULE_PRIORITY_ORDER=($(
                    for n in "${MODULE_NAMES[@]}"; do
                        echo "${MODULE_PRIORITY[$n]:-50}:$n"
                    done | sort -t: -k1 -n | cut -d: -f2
                ))
                boost_count=$((boost_count + 1))
                echo "  → $tool: رفع الأولوية (نجح في $count حالة، ثقة $cp%)" >> "$evidence_file"
            fi
        done <<< "$best"
    fi

    if [ "$boost_count" -gt 0 ]; then
        echo "" >> "$evidence_file"
        echo "تم تعديل أولويات $boost_count وحدة بناءً على المعرفة المخزنة." >> "$evidence_file"
        db_log "INFERENCE" "Boosted $boost_count modules based on KB"
    fi

    # Register evidence
    if [ -f "$evidence_file" ]; then
        local evidence_content=$(cat "$evidence_file")
        db_evidence_add "$INFERENCE_SESSION" "priority_boost" "Knowledge-based priority adjustment for $ftype" "$evidence_content"
    fi
}

inference_evidence() {
    local session="${1:-$INFERENCE_SESSION}"
    local evidence=$(db_query "SELECT decision, reason, sources, created_at FROM evidence WHERE session_id='$session' ORDER BY created_at DESC LIMIT 20")
    if [ -n "$evidence" ]; then
        echo "📋 Evidence Log"
        echo "══════════════"
        while IFS='|' read -r decision reason sources created_at; do
            echo ""
            echo "  [$created_at] $decision"
            echo "  سبب: $reason"
            [ -n "$sources" ] && echo "  تفاصيل: $(echo "$sources" | head -5)"
        done <<< "$evidence"
    else
        echo "  لا يوجد evidence في هذه الجلسة."
    fi
}
