MD_NAME="OleVBA"
MD_DESC="Analyze VBA macros in Office documents"
MD_TYPES="doc docx xls xlsx ppt pptx"
MD_DEPS="olevba"
MD_PRIORITY=34
MD_PRODUCES="macro_flag vba_code"

analyze_olevba() {
    local f="$1"
    header "OleVBA" "Office Macro Analysis"

    local out=$(olevba -c "$f" 2>/dev/null)
    [ -z "$out" ] && return

    local flags=$(echo "$out" | grep -iE "flag|ctf|secret|password|key|http" 2>/dev/null)
    [ -n "$flags" ] && while IFS= read -r line; do
        emit "macro_flag" "Macro finding: $line"
    done <<< "$flags"

    local decoded=$(echo "$out" | grep -oP '[A-Za-z0-9+/]{20,}={0,2}' 2>/dev/null | base64 -d 2>/dev/null)
    [ -n "$decoded" ] && emit "vba_code" "Base64 from macro: $decoded"
}
