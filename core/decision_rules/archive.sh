# ─────────────────────────────────────────────
# Archive/Embedded Data Rules
# ─────────────────────────────────────────────

de_rule_zip() {
    de_emitted_contains "^appended.*zip\|pk\|zip archive" && {
        de_prioritize "binwalk" "zip_brute"
        dt_matched "zip_rule"
        dt_reason "ZIP/PK signature detected in appended data"
    }
}

de_rule_after_iend() {
    de_emitted_contains "after.*iend\|trailing.*data\|data after.*iend" && {
        de_prioritize "append_data"
        dt_matched "after_iend_rule"
        dt_reason "data found after PNG IEND"
    }
}

de_rule_embedded_carve() {
    de_emitted_contains "embedded_file\|embedded files" && {
        de_prioritize "foremost"
        dt_matched "embedded_carve_rule"
        dt_reason "embedded files found — running foremost"
    }
}
