# ─────────────────────────────────────────────
# StegoForge Loop Protection Guard
# Prevents infinite loops and excessive re-runs
# Used by Decision Engine and engine.sh
# ─────────────────────────────────────────────

# ─── Loop Protection State ───
_LP_SESSION_START=0
_LP_FILE_ANALYSIS_COUNT=0
_LP_MAX_FILE_ANALYSES=5
_LP_MAX_MODULE_RETRIES=3
_LP_MAX_RULE_FIRE=10
_LP_TIMEOUT=300

declare -A _LP_FILE_STATE
declare -A _LP_MODULE_RUNS
declare -A _LP_RULE_FIRE_COUNT

lp_init_session() {
    _LP_SESSION_START=$(date +%s)
    _LP_FILE_ANALYSIS_COUNT=0
    _LP_MODULE_RUNS=()
    _LP_RULE_FIRE_COUNT=()
    _LP_FILE_STATE=()
}

lp_check_timeout() {
    [ "$(( $(date +%s) - _LP_SESSION_START ))" -gt "$_LP_TIMEOUT" ]
}

lp_check_module_retry() {
    local mod="$1"
    [ "${_LP_MODULE_RUNS[$mod]:-0}" -ge "$_LP_MAX_MODULE_RETRIES" ]
}

lp_track_module_run() {
    local mod="$1"
    _LP_MODULE_RUNS["$mod"]=$(( ${_LP_MODULE_RUNS[$mod]:-0} + 1 ))
}

lp_check_file_analysis() {
    [ "$_LP_FILE_ANALYSIS_COUNT" -ge "$_LP_MAX_FILE_ANALYSES" ]
}

lp_track_file_analysis() {
    _LP_FILE_ANALYSIS_COUNT=$(( _LP_FILE_ANALYSIS_COUNT + 1 ))
}

lp_check_rule_fire() {
    local rule="$1"
    [ "${_LP_RULE_FIRE_COUNT[$rule]:-0}" -ge "$_LP_MAX_RULE_FIRE" ]
}

lp_track_rule_fire() {
    local rule="$1"
    _LP_RULE_FIRE_COUNT["$rule"]=$(( ${_LP_RULE_FIRE_COUNT[$rule]:-0} + 1 ))
}

lp_file_changed() {
    local f="$1"
    local state="${_LP_FILE_STATE[$f]:-}"
    [ -z "$state" ] && return 1
    local hash=$(md5sum "$f" 2>/dev/null | cut -d' ' -f1)
    local mtime=$(stat -c%Y "$f" 2>/dev/null)
    local size=$(stat -c%s "$f" 2>/dev/null)
    [ "$state" != "${hash}|${mtime}|${size}" ]
}

lp_file_update() {
    local f="$1"
    local hash=$(md5sum "$f" 2>/dev/null | cut -d' ' -f1)
    local mtime=$(stat -c%Y "$f" 2>/dev/null)
    local size=$(stat -c%s "$f" 2>/dev/null)
    _LP_FILE_STATE["$f"]="${hash}|${mtime}|${size}"
}

lp_file_unchanged() {
    local f="$1"
    local state="${_LP_FILE_STATE[$f]:-}"
    [ -z "$state" ] && return 1
    ! lp_file_changed "$f"
}
