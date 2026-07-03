R='\033[0;31m'; G='\033[0;32m'; LG='\033[0;92m'; Y='\033[1;33m'
B='\033[0;34m'; C='\033[0;36m'; M='\033[0;35m'; W='\033[1;37m'; N='\033[0m'
BOLD='\033[1m'; DIM='\033[2m'

log()    { FINDINGS+=("$1"); }
warn()   { [ "$VERBOSE" = true ] && echo -e "  ${Y}[!]${N} $1" >&2; }
err()    { echo -e "  ${R}[X]${N} $1" >&2; }
info()   { [ "$VERBOSE" = true ] && echo -e "  ${B}[i]${N} $1"; }
header() { [ "$VERBOSE" = true ] && echo -e "\n${BOLD}${M}[$1]${N} ${W}$2${N}" && echo -e "${DIM}────────────────────────────────────────${N}"; }

emit() {
    local type="$1" data="$2"
    EMITTED+=("$type:$data")
    log "$data"
    [ "$VERBOSE" = true ] && echo -e "  ${C}[>$type]${N} $data"
}

save_artifact() {
    local src="$1" input_file="$2" label="$3"
    [ -f "$src" ] && [ -s "$src" ] || return
    local base=$(basename "$input_file" 2>/dev/null)
    local dir=$(dirname "$input_file" 2>/dev/null)
    local ext="${src##*.}"
    local name="${label}_${base%.*}.${ext}"
    local dest="${dir}/${name}"
    [ -f "$dest" ] && dest="${dir}/${name%.*}_$$.${ext}"
    cp "$src" "$dest" 2>/dev/null && echo -e "  ${G}[SAVED]${N} ${W}$dest${N}" >&2
}
