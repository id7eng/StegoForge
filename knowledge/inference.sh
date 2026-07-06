# ─────────────────────────────────────────────
# StegoForge Knowledge — Inference Engine
# ─────────────────────────────────────────────
# Uses accumulated knowledge to:
#   - Suggest best tools for a file type
#   - Suggest workflows based on similar cases
#   - Provide evidence for decisions
#   - Adjust module priorities dynamically

INFERENCE_SESSION=""
TECH_MODULE_MAP="${TOOL_DIR}/config/technique_module_map.json"

load_technique_module_map() {
    TECH_MODULE_MAP_LOADED=""
    [ -f "$TECH_MODULE_MAP" ] || return
    TECH_MODULE_MAP_LOADED=$(cat "$TECH_MODULE_MAP" 2>/dev/null)
}

module_for_technique() {
    local technique="$1"
    [ -z "$TECH_MODULE_MAP_LOADED" ] && { load_technique_module_map; }
    [ -z "$TECH_MODULE_MAP_LOADED" ] && { echo "$technique"; return; }
    local tkey=$(echo "$technique" | tr '[:upper:]' '[:lower:]')
    local mapped=$(echo "$TECH_MODULE_MAP_LOADED" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    key = '$tkey'.strip().lower()
    print(data.get(key, '$tkey'))
except: print('$tkey')
" 2>/dev/null | tail -1)
    [ -z "$mapped" ] && mapped="$technique"
    echo "$mapped"
}

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

    local ftype_norm=$(echo "$ftype" | tr '[:upper:]' '[:lower:]' | awk '{print $1}' | sed 's/,.*//')

    db_log "INFERENCE" "Analyzing: $file_path (type: $ftype_norm)"

    local suggestions=""
    local reasoning=""

    # ─── Load technique→module map ───
    load_technique_module_map

    # ─── 1. Best tools from statistics ───
    local best_tools=$(db_stats_best_for "$ftype_norm" 5)
    if [ -n "$best_tools" ]; then
        suggestions+="best_tools|$best_tools"$'\n'
        reasoning+="  • الأدوات الموصى بها (مرتبة حسب النجاح):"$'\n'
        while IFS='|' read -r tool technique conf count; do
            [ -z "$tool" ] && continue
            local cp=$(calc_pct "$conf")
            local mod=$(module_for_technique "$tool")
            local mod_hint=""
            [ "$mod" != "$tool" ] && mod_hint=" → [$mod]"
            reasoning+="    - $tool$mod_hint (تقنية: $technique, نجاح $cp% في $count حالة)"$'\n'
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
            local mod=$(module_for_technique "$tool")
            local mod_hint=""
            [ "$mod" != "$tool" ] && mod_hint=" → [$mod]"
            reasoning+="    - $tool$mod_hint $params (مذكور في $freq كتابة)"$'\n'
        done <<< "$workflows"
    fi

    # ─── 4. Workflow chains (2-step sequences) ───
    local chains=$(db_workflow_chains "$ftype_norm" 5)
    if [ -n "$chains" ]; then
        reasoning+="  • التسلسلات الأكثر نجاحاً:"$'\n'
        while IFS='|' read -r t1 a1 t2 a2 freq; do
            [ -z "$t1" ] && continue
            local m1=$(module_for_technique "$t1")
            local m2=$(module_for_technique "$t2")
            reasoning+="    → $t1 [$m1] ثم $t2 [$m2] (في $freq كتابة)"$'\n'
        done <<< "$chains"
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

    local -A kb_boosted=()
    local boost_count=0
    local penalty_count=0

    # Get best tools from knowledge base
    local best=$(db_stats_best_for "$ftype" 10)
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
            local mod=$(module_for_technique "$tool")
            if [ -n "${MODULE_PRIORITY[$mod]:-}" ] && [ -z "${kb_boosted[$mod]:-}" ]; then
                kb_boosted["$mod"]=1
                local current="${MODULE_PRIORITY[$mod]}"
                local boost=$(( cp / 10 ))
                [ "$boost" -lt 1 ] && boost=1
                local new=$(( current - boost ))
                [ "$new" -lt 1 ] && new=1
                MODULE_PRIORITY["$mod"]=$new
                boost_count=$((boost_count + 1))
                local mod_desc="$tool"
                [ "$mod" != "$tool" ] && mod_desc="$tool → [$mod]"
                echo "  → $mod_desc: رفع الأولوية (نجح في $count حالة، ثقة $cp%)" >> "$evidence_file"
            fi
        done <<< "$best"
    fi

    # Penalize tools that fail consistently
    local worst=$(db_stats_worst_for "$ftype" 5)
    if [ -n "$worst" ]; then
        echo "" >> "$evidence_file"
        echo "الأدوات منخفضة النجاح:" >> "$evidence_file"
        while IFS='|' read -r tool technique conf count; do
            [ -z "$tool" ] && continue
            local cp=$(calc_pct "$conf")
            local mod=$(module_for_technique "$tool")
            if [ -n "${MODULE_PRIORITY[$mod]:-}" ] && [ "${kb_boosted[$mod]:-}" != "1" ]; then
                kb_boosted["$mod"]=1
                local current="${MODULE_PRIORITY[$mod]}"
                local penalty=$(( (100 - cp) / 15 ))
                [ "$penalty" -lt 2 ] && penalty=2
                local new=$(( current + penalty ))
                MODULE_PRIORITY["$mod"]=$new
                penalty_count=$((penalty_count + 1))
                local mod_desc="$tool"
                [ "$mod" != "$tool" ] && mod_desc="$tool → [$mod]"
                echo "  → $mod_desc: خفض الأولوية (فشل في $((count - (count * cp / 100))) من $count حالة)" >> "$evidence_file"
            fi
        done <<< "$worst"
    fi

    if [ "$boost_count" -gt 0 ] || [ "$penalty_count" -gt 0 ]; then
        MODULE_PRIORITY_ORDER=($(
            for n in "${MODULE_NAMES[@]}"; do
                echo "${MODULE_PRIORITY[$n]:-50}:$n"
            done | sort -t: -k1 -n | cut -d: -f2
        ))
        db_log "INFERENCE" "Boosted $boost_count, penalized $penalty_count modules"
    fi
}

inference_best_path() {
    local file_type="$1"
    local ft_lower=$(echo "$file_type" | tr '[:upper:]' '[:lower:]' | awk '{print $1}' | sed 's/,.*//')

    # Best first tool
    local best_first=$(db_query "SELECT tool, COUNT(*) as freq FROM workflows wf WHERE wf.writeup_id IN (SELECT DISTINCT k.writeup_id FROM knowledge k WHERE k.knowledge_type='file_type' AND LOWER(k.value)='$ft_lower') AND wf.step_order=1 AND wf.tool != '' GROUP BY wf.tool ORDER BY freq DESC LIMIT 1")
    if [ -n "$best_first" ]; then
        local first_tool=$(echo "$best_first" | cut -d'|' -f1)
        local first_freq=$(echo "$best_first" | cut -d'|' -f2)
        local first_mod=$(module_for_technique "$first_tool")
        echo "BEST_FIRST:$first_tool|$first_freq|$first_mod"

        # Most common chain starting with this tool
        local best_chain=$(db_query "SELECT w1.tool, w2.tool FROM workflows w1 JOIN workflows w2 ON w1.writeup_id = w2.writeup_id AND w2.step_order = w1.step_order + 1 WHERE w1.tool='$first_tool' AND w1.step_order=1 AND w2.tool != '' AND w1.writeup_id IN (SELECT DISTINCT k.writeup_id FROM knowledge k WHERE k.knowledge_type='file_type' AND LOWER(k.value)='$ft_lower') GROUP BY w2.tool ORDER BY COUNT(*) DESC LIMIT 1")
        if [ -n "$best_chain" ]; then
            local next_tool=$(echo "$best_chain" | cut -d'|' -f2)
            local next_mod=$(module_for_technique "$next_tool")
            echo "BEST_CHAIN:$first_tool → $next_tool"
            echo "BEST_CHAIN_MODULES:$first_mod → $next_mod"
        fi
    fi

    # Best chain overall (most frequent 2-step)
    local top_chain=$(db_workflow_chains "$ft_lower" 1)
    if [ -n "$top_chain" ]; then
        local tc=$(echo "$top_chain" | head -1)
        echo "TOP_CHAIN:$tc"
    fi
}


