R='\033[0;31m'; G='\033[0;32m'; LG='\033[0;92m'; Y='\033[1;33m'
B='\033[0;34m'; C='\033[0;36m'; M='\033[0;35m'; W='\033[1;37m'; N='\033[0m'
BOLD='\033[1m'; DIM='\033[2m'

CMD_COUNTER_FILE=$(mktemp /tmp/stegoforge_cmd_XXXXXX 2>/dev/null) || CMD_COUNTER_FILE="/dev/null"
echo 0 > "$CMD_COUNTER_FILE" 2>/dev/null || true

CURRENT_MODULE=""
CONFIDENT_FINDINGS=()

inc_cmd_counter() {
    local val
    val=$(cat "$CMD_COUNTER_FILE" 2>/dev/null || echo 0)
    val=$((val + 1))
    echo "$val" > "$CMD_COUNTER_FILE"
    echo "$val"
}

log()    { FINDINGS+=("$1"); }
warn()   { [ "$VERBOSE" = true ] && echo -e "  ${Y}[!]${N} $1" >&2; }
err()    { echo -e "  ${R}[X]${N} $1" >&2; }

info()   {
    [ "$VERBOSE" = true ] && [ "${VERBOSE_CMD:-false}" = false ] && echo -e "  ${B}[i]${N} $1" >&2
}

header() {
    [ "$VERBOSE" = true ] || return
    if [ "${VERBOSE_CMD:-false}" = true ]; then return; fi
    echo -e "\n${BOLD}[$1]${N} ${W}$2${N}" >&2
    echo -e "${DIM}────────────────────────────────────────${N}" >&2
}

result() {
    [ "$VERBOSE" = true ] && [ "${VERBOSE_CMD:-false}" = false ] && echo -e "  ${G}✓${N} $1" >&2
}

emit() {
    local type="$1" data="$2"
    EMITTED+=("$type:$data")
    data=$(echo "$data" | sed 's/^Flag: *//; s/^FLAG: *//')
    local conf=40
    [ -n "$CURRENT_MODULE" ] && conf=$(score_confidence "$CURRENT_MODULE" "$data" "$type")
    CONFIDENT_FINDINGS+=("$CURRENT_MODULE|$conf|$data")
    log "$data"
    [ "$conf" -ge "$CONFIDENCE_MIN" ] && [ "$VERBOSE" = true ] && [ "${VERBOSE_CMD:-false}" = false ] && echo -e "  ${C}▶${N} [${conf}%] $data" >&2
}

save_artifact() {
    local src="$1" input_file="$2" label="$3"
    [ -f "$src" ] && [ -s "$src" ] || return
    label=$(echo "$label" | tr -cd 'a-zA-Z0-9_-')
    local base=$(basename "$input_file" 2>/dev/null)
    local dir=$(dirname "$input_file" 2>/dev/null)
    local ext="${src##*.}"
    local name="${label}_${base%.*}.${ext}"
    local dest="${dir}/${name}"
    [ -f "$dest" ] && dest="${dir}/${name%.*}_$$.${ext}"
    cp "$src" "$dest" 2>/dev/null && echo -e "  ${G}[SAVED]${N} ${W}$dest${N}" >&2
}

log_cmd() {
    local cmd_str toolname
    printf -v cmd_str '%s ' "$@"
    if [ "${VERBOSE_CMD:-false}" = true ]; then
        cmd_str="${cmd_str//$'\n'/ }"
        cmd_str="${cmd_str//$'\r'/ }"
        toolname="${1##*/}"
        echo >&2
        echo -e "  ${BOLD}[${W}${toolname}${N}${BOLD}]${N}" >&2
        printf "  ${G}\$ ${W}%s${N}\n" "$cmd_str" >&2
        echo >&2
    fi
}

run_cmd() {
    log_cmd "$@"
    "$@" 2>/dev/null
}

log_cmd_str() {
    if [ "${VERBOSE_CMD:-false}" = true ]; then
        local msg toolname
        msg="$*"
        msg="${msg//$'\n'/ }"
        msg="${msg//$'\r'/ }"
        toolname="${1%% *}"; toolname="${toolname##*/}"
        echo >&2
        echo -e "  ${BOLD}[${W}${toolname}${N}${BOLD}]${N}" >&2
        printf "  ${G}\$ ${W}%s${N}\n" "$msg" >&2
        echo >&2
    fi
}
