# ─────────────────────────────────────────────
# Module API — standard interface for modules
# ─────────────────────────────────────────────

module_init() {
    local name="${1:-}"
    [ -n "$name" ] && CURRENT_MODULE="$name"
}

emit_flag()       { emit "flag"       "$1"; }
emit_keyword()    { emit "keyword"    "$1"; }
emit_base64()     { emit "base64"     "$1"; }
emit_xor_key()    { emit "xor_key"    "$1"; }
emit_password()   { emit "password"   "$1"; }
emit_partial()    { emit "partial_flag" "$1"; }
emit_data()       { emit "data"       "$1"; }
emit_finding()    { emit "$1"         "$2"; }
