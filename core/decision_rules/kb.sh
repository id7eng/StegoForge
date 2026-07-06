# ─────────────────────────────────────────────
# Knowledge Base Integration Rules
# ─────────────────────────────────────────────

de_rule_kb_suggestions() {
    [ ${#_DECIDE_KB_HINT[@]} -eq 0 ] && return
    local _entry _mod
    for _entry in "${_DECIDE_KB_HINT[@]}"; do
        _mod="${_entry%%|*}"
        [ -z "$_mod" ] && continue
        de_prioritize "$_mod"
    done
    dt_matched "kb_suggestions_rule"
    dt_reason "knowledge base suggests these modules for this file type"
}
