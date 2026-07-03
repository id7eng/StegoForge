RULES_FILE="${CONFIG_DIR}/priority_rules.json"

load_priority_rules() {
    [ -f "$RULES_FILE" ] || {
        info "No priority rules found at $RULES_FILE"
        return 1
    }
    return 0
}

get_priority_boosted_modules() {
    local ftype="$1"
    local ftype_lower=$(echo "$ftype" | tr '[:upper:]' '[:lower:]' | cut -d'/' -f1 | cut -d' ' -f1)
    [ -z "$ftype_lower" ] && return

    local rules
    rules=$(jq -r ".file_rules.\"$ftype_lower\"" "$RULES_FILE" 2>/dev/null)
    if [ "$rules" = "null" ]; then
        rules=$(jq -r ".file_rules.\"$ftype_lower\"" "$RULES_FILE" 2>/dev/null)
        if [ "$rules" = "null" ]; then
            return
        fi
    fi

    local inherit
    inherit=$(echo "$rules" | jq -r '.inherit // empty' 2>/dev/null)
    if [ -n "$inherit" ]; then
        rules=$(jq -r ".file_rules.\"$inherit\"" "$RULES_FILE" 2>/dev/null)
        [ "$rules" = "null" ] && return
    fi

    local base_boost
    base_boost=$(echo "$rules" | jq -r '.base_boost // 10' 2>/dev/null)

    local boosted_modules=()
    while IFS= read -r mod; do
        [ -n "$mod" ] && boosted_modules+=("$mod")
    done < <(echo "$rules" | jq -r '.tool_priority[] // empty' 2>/dev/null)

    for name in "${boosted_modules[@]}"; do
        local current_prio="${MODULE_PRIORITY[$name]:-50}"
        local new_prio=$((current_prio - base_boost))
        [ "$new_prio" -lt 1 ] && new_prio=1
        MODULE_PRIORITY["$name"]=$new_prio
    done

    export PRIORITY_RULES_JSON="$rules"
    export PRIORITY_RULES_BOOST="$base_boost"
    export PRIORITY_RULES_MODULES="${boosted_modules[*]}"
}

get_conditional_boost() {
    local module_name="$1"
    local output="$2"

    [ -z "$PRIORITY_RULES_JSON" ] && return
    [ -z "$output" ] && return

    local conds
    conds=$(echo "$PRIORITY_RULES_JSON" | jq -c '.conditional_priority[] // empty' 2>/dev/null)
    [ -z "$conds" ] && return

    while IFS= read -r cond; do
        [ -z "$cond" ] && continue
        local keywords
        keywords=$(echo "$cond" | jq -r '.keywords[]' 2>/dev/null)
        local match=false
        while IFS= read -r kw; do
            [ -z "$kw" ] && continue
            echo "$output" | grep -qiF "$kw" 2>/dev/null && { match=true; break; }
        done <<< "$keywords"

        if $match; then
            while IFS= read -r boost_mod; do
                [ -z "$boost_mod" ] && continue
                local current_prio="${MODULE_PRIORITY[$boost_mod]:-50}"
                local new_prio=$((current_prio - PRIORITY_RULES_BOOST - 5))
                [ "$new_prio" -lt 1 ] && new_prio=1
                MODULE_PRIORITY["$boost_mod"]=$new_prio
            done < <(echo "$cond" | jq -r '.boost[]' 2>/dev/null)
        fi
    done <<< "$conds"
}
