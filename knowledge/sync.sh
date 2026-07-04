# ─────────────────────────────────────────────
# StegoForge Knowledge — Sync Engine
# ─────────────────────────────────────────────

sync_all() {
    db_log "SYNC" "Starting full sync..."
    local sources=$(db_source_list)
    local count=0
    while IFS='|' read -r id name stype url enabled last_sync; do
        [ -z "$id" ] && continue
        [ "$enabled" = "0" ] && { db_log "SYNC" "Skipping disabled source: $name"; continue; }
        sync_source "$id" "$stype" "$url"
        count=$((count + 1))
    done <<< "$sources"
    db_log "SYNC" "Finished syncing $count sources"
}

sync_source() {
    local source_id="$1" source_type="$2" source_url="$3"

    db_log "SYNC" "Syncing source #$source_id ($source_type: $source_url)"
    local log_id=$(db_sync_start "$source_id")

    local items=$(connector_run "$source_id" "$source_type" "$source_url" "discover" 2>/dev/null)
    local found=0 imported=0

    while IFS='|' read -r item_url item_name repo_name; do
        [ -z "$item_url" ] && continue
        found=$((found + 1))

        # Skip if already imported (by URL)
        if db_writeup_exists "$item_url"; then
            continue
        fi

        # Fetch content
        local content=$(connector_run "$source_id" "$source_type" "$source_url" "fetch" "$item_url" 2>/dev/null)
        [ -z "$content" ] && continue

        # Generate hash for dedup
        local hash=$(echo "$content" | md5sum | cut -d' ' -f1)
        local existing=$(db_writeup_by_hash "$hash")
        [ -n "$existing" ] && continue

        # Parse the writeup
        local parsed=$(parse_writeup "$content" "$item_url" 2>/dev/null)
        local title=$(echo "$parsed" | grep "^TITLE:" | sed 's/^TITLE://')
        local category=$(echo "$parsed" | grep "^CATEGORY:" | sed 's/^CATEGORY://')
        local challenge=$(echo "$parsed" | grep "^CHALLENGE:" | sed 's/^CHALLENGE://')
        local pub_date=$(echo "$parsed" | grep "^DATE:" | sed 's/^DATE://')
        local summary=$(echo "$parsed" | grep "^SUMMARY:" | sed 's/^SUMMARY://')
        local writeup_body=$(echo "$parsed" | sed -n '/^---CONTENT---$/,$ p' | tail -n +2)

        # Insert writeup
        db_writeup_insert "$title" "$challenge" "$category" "$item_url" "$hash" "$pub_date" "$summary"

        local wid=$(db_writeup_by_hash "$hash")

        if [ -n "$wid" ]; then
            # Extract all knowledge types
            import_knowledge "$wid" "$writeup_body"
            imported=$((imported + 1))
        fi

    done <<< "$items"

    db_sync_finish "$log_id" "success" "$found" "$imported"
    db_log "SYNC" "Source #$source_id: $found found, $imported imported"
}

import_knowledge() {
    local writeup_id="$1" content="$2"
    [ -z "$content" ] && return

    # ─── File Types ───
    while read -r ft; do
        [ -n "$ft" ] && db_knowledge_insert "$writeup_id" "file_type" "$(echo "$ft" | tr '[:upper:]' '[:lower:]')" "$ft" 0.7 ""
    done <<< "$(extract_file_types "$content")"

    # ─── Tools ───
    while read -r tool; do
        [ -n "$tool" ] && db_knowledge_insert "$writeup_id" "tool" "$(echo "$tool" | tr '[:upper:]' '[:lower:]')" "$tool" 0.9 ""
    done <<< "$(extract_tools "$content")"

    # ─── Commands ───
    while read -r cmd; do
        [ -n "$cmd" ] && db_knowledge_insert "$writeup_id" "command" "$(echo "$cmd" | cut -d' ' -f1)" "$cmd" 0.8 ""
    done <<< "$(extract_commands "$content")"

    # ─── Techniques ───
    while read -r tech; do
        [ -n "$tech" ] && db_knowledge_insert "$writeup_id" "technique" "$(echo "$tech" | tr '[:upper:]' '[:lower:]')" "$tech" 0.75 ""
    done <<< "$(extract_techniques "$content")"

    # ─── Passwords ───
    while read -r pw; do
        [ -n "$pw" ] && db_knowledge_insert "$writeup_id" "password" "$pw" "$pw" 0.85 ""
    done <<< "$(extract_passwords "$content")"

    # ─── Flag Patterns ───
    while read -r fp; do
        [ -n "$fp" ] && db_knowledge_insert "$writeup_id" "flag_pattern" "$fp" "$fp" 1.0 ""
    done <<< "$(extract_flag_patterns "$content")"

    # ─── Encodings ───
    while read -r enc; do
        [ -n "$enc" ] && db_knowledge_insert "$writeup_id" "encoding" "$(echo "$enc" | tr '[:upper:]' '[:lower:]')" "$enc" 0.7 ""
    done <<< "$(extract_encodings "$content")"

    # ─── OS ───
    while read -r os; do
        [ -n "$os" ] && db_knowledge_insert "$writeup_id" "os" "$(echo "$os" | tr '[:upper:]' '[:lower:]')" "$os" 0.6 ""
    done <<< "$(extract_os "$content")"

    # ─── Indicators ───
    while read -r ind; do
        [ -n "$ind" ] && db_knowledge_insert "$writeup_id" "indicator" "$ind" "$ind" 0.5 ""
    done <<< "$(extract_indicators "$content")"

    # ─── Workflow ───
    local raw_wf=$(extract_workflow "$content" )
    if [ -n "$raw_wf" ]; then
        local steps=$(workflow_to_steps "$raw_wf")
        while IFS='|' read -r step_info action tool params; do
            local step_num=$(echo "$step_info" | sed 's/^STEP://')
            [ -z "$step_num" ] && continue
            db_workflow_insert "$writeup_id" "$step_num" "$action" "$tool" "$params" "success"
            # Update statistics
            local ft=$(extract_file_types "$content" | head -1)
            local ft_lower=$(echo "$ft" | tr '[:upper:]' '[:lower:]')
            [ -n "$ft_lower" ] && [ -n "$tool" ] && db_stats_update "$ft_lower" "$tool" "$action" 1
        done <<< "$steps"
    fi

    db_log "KB" "Import complete for writeup #$writeup_id"
}

sync_add_source() {
    local name="$1" stype="$2" url="$3" interval="${4:-86400}"
    db_source_add "$name" "$stype" "$url" "$interval"
    local id=$(db_query "SELECT id FROM sources WHERE url='$(echo "$url" | sed "s/'/''/g")'" | head -1)
    if [ -n "$id" ]; then
        db_log "SYNC" "Added source #$id: $name ($stype)"
        # Auto-sync new source
        sync_source "$id" "$stype" "$url"
    fi
}

add_default_sources() {
    local defaults_file="${KNOWLEDGE_DIR}/default_sources.json"
    [ ! -f "$defaults_file" ] && { db_log "KB" "No default_sources.json found"; return; }

    local count=0
    while IFS= read -r src; do
        [ -z "$src" ] && continue
        local name=$(echo "$src" | jq -r '.name // empty' 2>/dev/null)
        local stype=$(echo "$src" | jq -r '.type // empty' 2>/dev/null)
        local url=$(echo "$src" | jq -r '.url // empty' 2>/dev/null)
        local interval=$(echo "$src" | jq -r '.interval // 86400' 2>/dev/null)
        [ -z "$name" ] || [ -z "$stype" ] || [ -z "$url" ] && continue

        local exists=$(db_query "SELECT id FROM sources WHERE url='$(echo "$url" | sed "s/'/''/g")'")
        if [ -z "$exists" ]; then
            db_source_add "$name" "$stype" "$url" "$interval"
            count=$((count + 1))
            db_log "KB" "Added default source: $name ($stype)"
        fi
    done < <(jq -c '.sources[]' "$defaults_file" 2>/dev/null)

    db_log "KB" "Added $count new default sources"
}

sync_source_by_id() {
    local id="$1"
    local row=$(db_source_get "$id")
    if [ -z "$row" ]; then
        db_log "ERROR" "Source #$id not found"
        return
    fi
    local name=$(echo "$row" | cut -d'|' -f2)
    local stype=$(echo "$row" | cut -d'|' -f3)
    local url=$(echo "$row" | cut -d'|' -f4)
    sync_source "$id" "$stype" "$url"
}
