# ─────────────────────────────────────────────
# StegoForge Decision Engine (DE)
# Loader — sources sub-components and provides
# the core evaluation loop, trace, and helpers.
# Rules are auto-discovered via declare -F.
# ─────────────────────────────────────────────

source "${CORE_DIR}/loop_guard.sh"

# ─── Decision State ───
declare -a _DECIDE_PRIORITIZE _DECIDE_SKIP
_DECIDE_STOP=false
_DECIDE_IGNORE_FLAG=false
declare -a DE_RULES

# ─── KB Integration ───
declare -a _DECIDE_KB_HINT

# ═══════════════════════════════════════════
# RULES — each file sources its de_rule_* functions
# ═══════════════════════════════════════════

for _de_rule_file in "${CORE_DIR}/decision_rules/"*.sh; do
    [ -f "$_de_rule_file" ] && source "$_de_rule_file"
done
unset _de_rule_file

# ═══════════════════════════════════════════
# INIT
# ═══════════════════════════════════════════

de_init() {
    DE_RULES=()
    while IFS= read -r func; do
        DE_RULES+=("$func")
    done < <(declare -F 2>/dev/null | sed 's/declare -f //' | grep '^de_rule_')
}

# ═══════════════════════════════════════════
# EVALUATION
# ═══════════════════════════════════════════

de_evaluate() {
    local _de_ftype="$1" _de_last_mod="$2"
    _DECIDE_PRIORITIZE=()
    _DECIDE_SKIP=()
    _DECIDE_STOP=false
    _DECIDE_IGNORE_FLAG=false

    _LP_RULE_FIRE_COUNT=()

    lp_check_timeout && { _DECIDE_STOP=true; return; }
    lp_check_file_analysis && { _DECIDE_STOP=true; return; }

    for rule in "${DE_RULES[@]}"; do
        lp_check_rule_fire "$rule" && continue
        "$rule"
        lp_track_rule_fire "$rule"
    done

    :
}

# ═══════════════════════════════════════════
# DECISION TRACE (-vv only)
# ═══════════════════════════════════════════

_DT_BUFFER=""
_DT_MATCHED=""
_DT_SKIPPED=""
_DT_REASON=""

dt_matched()   { _DT_MATCHED+="  $1"$'\n'; }
dt_action()    { _DT_BUFFER+="  $1"$'\n'; }
dt_skipped()   { _DT_SKIPPED+="  $1"$'\n'; }
dt_reason()    { _DT_REASON+="  $1"$'\n'; }

de_trace_flush() {
    local had_decision=false
    [ -n "$_DT_BUFFER" ] && had_decision=true
    $had_decision || return
    echo -e "\n${C}══════════════════════════════════════════════${N}" >&2
    echo -e "${BOLD}[Decision]${N}" >&2
    [ -n "$_DT_MATCHED" ] && echo -e "${W}Matched Rule:${N}" >&2 && echo -e "$_DT_MATCHED" >&2
    [ -n "$_DT_BUFFER" ] && echo -e "${W}Action:${N}" >&2 && echo -e "$_DT_BUFFER" >&2
    [ -n "$_DT_SKIPPED" ] && echo -e "${W}Skipped:${N}" >&2 && echo -e "$_DT_SKIPPED" >&2
    [ -n "$_DT_REASON" ] && echo -e "${W}Reason:${N}" >&2 && echo -e "$_DT_REASON" >&2
    echo -e "${C}══════════════════════════════════════════════${N}" >&2
}

# ═══════════════════════════════════════════
# HELPERS — used by rules and engine.sh
# ═══════════════════════════════════════════

de_emitted_contains() {
    local pattern="$1" _ev
    for _ev in "${EMITTED[@]}"; do
        echo "$_ev" | grep -qiE "$pattern" 2>/dev/null && return 0
    done
    return 1
}

de_emitted_type() {
    local type="$1" _ev
    for _ev in "${EMITTED[@]}"; do
        local _et="${_ev%%:*}"
        [ "$_et" = "$type" ] && return 0
    done
    return 1
}

de_prioritize() {
    local mod
    for mod in "$@"; do
        [ -z "$mod" ] && continue
        if [ "${_LP_MODULE_RUNS[$mod]:-0}" -ge "$_LP_MAX_MODULE_RETRIES" ]; then
            dt_action "PRIORITIZE $mod (skipped: max retries reached)"
            continue
        fi
        local _existing
        for _existing in "${_DECIDE_PRIORITIZE[@]}"; do
            [ "$_existing" = "$mod" ] && continue 2
        done
        _DECIDE_PRIORITIZE+=("$mod")
        dt_action "PRIORITIZE $mod"
    done
}

de_skip() {
    local mod
    for mod in "$@"; do
        local _existing
        for _existing in "${_DECIDE_SKIP[@]}"; do
            [ "$_existing" = "$mod" ] && continue 2
        done
        _DECIDE_SKIP+=("$mod")
        dt_skipped "$mod"
    done
}

de_stop() {
    _DECIDE_STOP=true
    dt_action "STOP"
}

de_ignore_flag() {
    _DECIDE_IGNORE_FLAG=true
    dt_action "IGNORE_FLAG (deferred — potential false positive)"
}

de_clear_emitted_type() {
    local type="$1"
    local -a _new_emitted=()
    for _ev in "${EMITTED[@]}"; do
        local _et="${_ev%%:*}"
        [ "$_et" = "$type" ] && continue
        _new_emitted+=("$_ev")
    done
    EMITTED=("${_new_emitted[@]}")
    dt_action "CLEAR emitted type: $type"
}
