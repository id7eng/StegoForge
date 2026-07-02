MD_NAME="JPHide"
MD_DESC="Extract data from jphide/jpseek embedded JPEGs"
MD_TYPES="jpg jpeg"
MD_DEPS="jpseek"
MD_PRIORITY=43
MD_PRODUCES="jphide_data flag"

analyze_jphide() {
    local f="$1" wl="$2"
    header "JPHide" "Data extraction"

    local outfile="${OUTDIR}/carved/jphide_out"
    if jpseek "$f" "$outfile" 2>/dev/null; then
        [ -f "$outfile" ] && {
            local content=$(strings "$outfile" 2>/dev/null)
            [ -n "$content" ] && emit "jphide_data" "JPHide data: $content"
            rm -f "$outfile" 2>/dev/null
            return
        }
    fi

    [ -z "$wl" ] && return
    [ ! -f "$wl" ] && return

    info "Trying wordlist..."
    while IFS= read -r p; do
        [ -z "$p" ] && continue
        rm -f "$outfile" 2>/dev/null
        if jpseek "$f" "$outfile" "$p" 2>/dev/null; then
            [ -f "$outfile" ] && {
                local content=$(strings "$outfile" 2>/dev/null)
                [ -n "$content" ] && {
                    emit "password" "JPHide password: $p"
                    emit "jphide_data" "$content"
                }
                rm -f "$outfile" 2>/dev/null
            }
            return
        fi
    done < "$wl"
    info "No JPHide password found"
}
