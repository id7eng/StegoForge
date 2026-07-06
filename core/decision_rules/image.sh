# ─────────────────────────────────────────────
# Image-Specific Rules
# ─────────────────────────────────────────────

de_rule_crc() {
    de_emitted_contains "crc.*mismatch\|crc_fixed" && {
        de_prioritize "png_crc" "repair"
        dt_matched "crc_rule"
        dt_reason "CRC mismatch detected"
    }
}

de_rule_crc_fixed() {
    de_emitted_type "crc_fixed" && {
        de_prioritize "png_check"
        dt_matched "crc_fixed_rule"
        dt_reason "CRC was fixed — re-checking image"
    }
}

de_rule_thumbnail() {
    de_emitted_contains "thumbnail" && {
        de_prioritize "exif_thumbnail"
        dt_matched "thumbnail_rule"
        dt_reason "EXIF thumbnail detected"
    }
}

de_rule_lsb_hint() {
    de_emitted_contains "lsb\|bit.?plane\|zsteg" && {
        de_prioritize "zsteg" "cross_lsb" "bit_plane"
        dt_matched "lsb_hint_rule"
        dt_reason "LSB stego hint detected"
    }
}

de_rule_qr_skip_ocr() {
    de_emitted_type "qr_data" && {
        de_skip "ocr"
        de_skip "qr"
        dt_matched "qr_skip_ocr_rule"
        dt_reason "QR data already decoded — skipping OCR"
    }
}
