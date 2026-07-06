# ─────────────────────────────────────────────
# Crypto/Encoding Rules
# ─────────────────────────────────────────────

de_rule_b64() {
    de_emitted_contains "base64" && {
        de_prioritize "base64_full"
        dt_matched "base64_rule"
        dt_reason "emitted data contains base64"
    }
}

de_rule_hex() {
    de_emitted_contains "hex" && {
        de_prioritize "xor_brute"
        dt_matched "hex_rule"
        dt_reason "emitted data contains hex"
    }
}

de_rule_b64_string() {
    de_emitted_type "base64_string" && {
        de_prioritize "base64_full"
        dt_matched "b64_string_rule"
        dt_reason "strings module emitted base64_string"
    }
}

de_rule_rot_suspect() {
    [ "$_de_last_mod" != "strings" ] && return
    local _suspect=false _ev
    for _ev in "${EMITTED[@]}"; do
        local _et="${_ev%%:*}" _data="${_ev#*:}"
        [ "$_et" != "flag" ] && continue
        echo "$_data" | grep -qiE '^(picoCTF|HTB|THM|NCSE|FLAG|flag|CTF)\{' && continue
        echo "$_data" | grep -qP '^[A-Za-z0-9_]+\{[^}]{3,}\}$' && { _suspect=true; break; }
    done
    if $_suspect; then
        de_clear_emitted_type "flag"
        local -a _new_cf=()
        for _cf in "${CONFIDENT_FINDINGS[@]}"; do
            local _cf_mod="${_cf%%|*}"
            [ "$_cf_mod" = "strings" ] && continue
            _new_cf+=("$_cf")
        done
        CONFIDENT_FINDINGS=("${_new_cf[@]}")
        de_prioritize "rot_brute"
        dt_matched "rot_suspect_rule"
        dt_reason "strings emitted generic-format flag (ROT candidate) — deferring and prioritizing rot_brute"
    fi
}
