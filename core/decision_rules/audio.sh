# ─────────────────────────────────────────────
# Audio-Specific Rules
# ─────────────────────────────────────────────

de_rule_audio_skip_image() {
    case "$_de_ftype" in
        wav*|mp3*|au*|wave*|flac*|ogg*)
            de_skip "binary_border" "fft_domain" "stepic"
            dt_matched "audio_skip_image_rule"
            dt_reason "audio file type — skipping image-specific tools"
            ;;
    esac
}
