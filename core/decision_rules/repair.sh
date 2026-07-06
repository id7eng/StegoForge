# ─────────────────────────────────────────────
# Repair/Recovery/Tool Rules
# ─────────────────────────────────────────────

de_rule_repaired() {
    de_emitted_type "repaired_file" && {
        de_prioritize "metadata" "png_check" "strings"
        dt_matched "repaired_rule"
        dt_reason "repaired file available — prioritizing re-analysis"
    }
}

de_rule_steg_tool() {
    de_emitted_type "steg_tool" && {
        de_prioritize "steghide" "outguess" "jphide"
        dt_matched "steg_tool_rule"
        dt_reason "steg tool detected in stegdetect output"
    }
}

de_rule_password() {
    de_emitted_type "password" && {
        de_prioritize "stegseek" "steghide"
        dt_matched "password_rule"
        dt_reason "password discovered — trying stego tools"
    }
}

de_rule_disk_part() {
    de_emitted_type "disk_partition" && {
        de_prioritize "disk_forensics"
        dt_matched "disk_part_rule"
        dt_reason "disk partition detected"
    }
}

de_rule_confident_flag_stop() {
    local _high_conf_found=false _ev
    for _ev in "${EMITTED[@]}"; do
        local _et="${_ev%%:*}"
        [ "$_et" != "flag" ] && continue
    done
    local _cf
    for _cf in "${CONFIDENT_FINDINGS[@]}"; do
        local _cf_mod="${_cf%%|*}" _rest="${_cf#*|}" _cf_conf="${_rest%%|*}"
        [[ "$_cf_conf" =~ ^[0-9]+$ ]] && [ "$_cf_conf" -ge 90 ] && { _high_conf_found=true; break; }
    done
    if $_high_conf_found; then
        de_stop
        dt_matched "confident_flag_stop_rule"
        dt_reason "high confidence flag (90%+) found — stopping analysis"
    fi
}
