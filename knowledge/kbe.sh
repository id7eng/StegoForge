#!/bin/bash
# StegoForge Knowledge Base Engine (KBE)
# Usage: stegoforge knowledge <command> [options]
#
# Commands:
#   init              Initialize database
#   sync [--auto]     Sync all sources (--auto adds default sources first)
#   sync-source <id>  Sync specific source
#   import <path>     Import writeups from local file/directory
#   add-source        Add a new knowledge source
#   list-sources      List all sources
#   remove-source <id> Remove a source
#   info              Show KB statistics
#   search <term>     Search knowledge base
#   suggest <file>    Suggest workflow for a file
#   evidence [session] Show reasoning evidence
#   stats [file_type] Show tool success statistics
#   connectors        List available connector types
#   setup-auto-sync   Set up daily automatic sync (cron)
#   setup-login-sync  Set up sync on login
#   stop-auto         Stop automatic sync
#   auto-status       Show auto-sync status
#   auto-defaults     Add all default built-in sources
#   prune             KB maintenance

KNOWLEDGE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${KNOWLEDGE_DIR}/db.sh"
source "${KNOWLEDGE_DIR}/sync.sh"
source "${KNOWLEDGE_DIR}/inference.sh"
source "${KNOWLEDGE_DIR}/connectors/connector.sh"
source "${KNOWLEDGE_DIR}/extractors/parser.sh"
source "${KNOWLEDGE_DIR}/extractors/workflow.sh"

kbe_usage() {
    echo "Usage: stegoforge knowledge <command> [options]"
    echo ""
    echo "Commands:"
    echo "  init                     Initialize knowledge database"
    echo "  sync [--auto]            Sync all sources (--auto adds default sources first)"
    echo "  sync-source <id>         Sync specific source"
    echo "  import <path>            Import writeups from local file/directory"
    echo "  add-source               Add a new knowledge source"
    echo "  list-sources             List all sources"
    echo "  remove-source <id>       Remove a source"
    echo "  info                     Show KB statistics"
    echo "  search <term>            Search the knowledge base"
    echo "  suggest <file>           Suggest analysis workflow for a file"
    echo "  evidence [session]       Show reasoning evidence"
    echo "  stats [file_type]        Show tool success statistics"
    echo "  connectors               List available connector types"
    echo "  setup-auto-sync          Set up daily automatic sync (cron)"
    echo "  setup-login-sync         Set up sync on login"
    echo "  stop-auto                Stop automatic sync"
    echo "  auto-status              Show auto-sync status"
    echo "  auto-defaults            Add all default built-in sources"
    echo "  prune                    KB maintenance"
    exit 0
}

kbe_main() {
    local cmd="$1"; shift

    case "$cmd" in
        init)
            db_init
            db_log "KBE" "Knowledge database initialized"
            ;;

        sync)
            db_init
            local auto_flag="${1:-}"
            if [ "$auto_flag" = "--auto" ]; then
                db_log "KB" "Adding default sources before sync..."
                add_default_sources
            fi
            local max_per_run=10
            [ "$auto_flag" = "--auto" ] && max_per_run=10
            sync_all "$max_per_run"
            ;;

        sync-source)
            local id="$1"
            [ -z "$id" ] && { echo "Usage: stegoforge knowledge sync-source <id>"; exit 1; }
            db_init
            sync_source_by_id "$id"
            ;;

        import)
            local path="$1"
            [ -z "$path" ] && { echo "Usage: stegoforge knowledge import <path>"; exit 1; }
            [ ! -e "$path" ] && { echo "  Path not found: $path"; exit 1; }
            db_init
            if [ -d "$path" ]; then
                local files=()
                while IFS= read -r -d '' f; do
                    files+=("$f")
                done < <(find "$path" -type f \( -name '*.md' -o -name '*.html' -o -name '*.pdf' -o -name '*.txt' -o -name '*.rst' \) -print0 2>/dev/null)
                db_log "IMPORT" "Importing ${#files[@]} files from $path"
                for f in "${files[@]}"; do
                    import_single_file "$f"
                done
            else
                import_single_file "$path"
            fi
            ;;

        add-source)
            echo "Enter source name:"
            read -r name
            echo "Enter source type (github/local/rss/ctftime):"
            read -r stype
            echo "Enter source URL:"
            read -r url
            echo "Enter sync interval in seconds (default 86400):"
            read -r interval
            interval="${interval:-86400}"
            db_init
            sync_add_source "$name" "$stype" "$url" "$interval"
            ;;

        list-sources)
            db_init
            echo "Knowledge Sources"
            echo "══════════════════"
            local list=$(db_source_list)
            if [ -z "$list" ]; then
                echo "  No sources configured."
                echo "  Add one with: stegoforge knowledge add-source"
            else
                printf "  %-4s %-22s %-10s %-30s %-8s %s\n" "ID" "Name" "Type" "URL" "Enabled" "Last Sync"
                echo "  ─────────────────────────────────────────────────────────────────────────────────"
                while IFS='|' read -r id name stype url enabled last_sync; do
                    [ -z "$id" ] && continue
                    local status="$( [ "$enabled" = "1" ] && echo "✅" || echo "❌" )"
                    last_sync="${last_sync:---}"
                    printf "  %-4s %-22s %-10s %-30s %-8s %s\n" "$id" "$name" "$stype" "$url" "$status" "$last_sync"
                done <<< "$list"
            fi
            ;;

        remove-source)
            local id="$1"
            [ -z "$id" ] && { echo "Usage: stegoforge knowledge remove-source <id>"; exit 1; }
            db_exec "DELETE FROM sources WHERE id=$id"
            db_log "KBE" "Removed source #$id"
            ;;

        info)
            db_init
            echo "Knowledge Base Statistics"
            echo "═══════════════════════════"
            db_stats_overview
            ;;

        search)
            local term="$1"
            [ -z "$term" ] && { echo "Usage: stegoforge knowledge search <term>"; exit 1; }
            db_init
            local results=$(db_knowledge_search "$term")
            if [ -z "$results" ]; then
                echo "  No results for '$term'."
            else
                echo "Search results for: $term"
                echo "═══════════════════════════"
                while IFS='|' read -r ktype key value conf challenge; do
                    [ -z "$key" ] && continue
                    local cp=$(calc_pct "$conf" 2>/dev/null)
                    printf "  [%-12s] %-25s → %s (ثقة %s%%) [%s]\n" "$ktype" "$key" "$value" "$cp" "${challenge:---}"
                done <<< "$results"
            fi
            ;;

        suggest)
            local file="$1"
            [ -z "$file" ] && { echo "Usage: stegoforge knowledge suggest <file>"; exit 1; }
            [ ! -f "$file" ] && { echo "  File not found: $file"; exit 1; }
            db_init
            inference_init

            local ftype=$(file -b "$file" 2>/dev/null)
            echo "Knowledge-Based Analysis for: $(basename "$file")"
            echo "══════════════════════════════════════════"
            echo "  Type: $ftype"
            echo ""

            local analysis=$(inference_analyze "$file" "$ftype")
            local reasoning=$(echo "$analysis" | sed -n '/^REASONING:/,/^SUGGESTIONS:/p' | sed '1s/^REASONING://; $d')

            if [ -n "$reasoning" ]; then
                echo "Analysis Reasoning:"
                echo "$reasoning"
            else
                echo "  No knowledge data for this file type yet."
            fi

            local best_path=$(inference_best_path "$ftype" 2>/dev/null)
            if [ -n "$best_path" ]; then
                echo ""
                echo "Recommended Path:"
                while IFS= read -r line; do
                    case "$line" in
                        BEST_FIRST:*)
                            local bf="${line#BEST_FIRST:}"
                            local bf_tool=$(echo "$bf" | cut -d'|' -f1)
                            local bf_freq=$(echo "$bf" | cut -d'|' -f2)
                            local bf_mod=$(echo "$bf" | cut -d'|' -f3)
                            echo "  1. Start with: $bf_tool → [$bf_mod] (most used, $bf_freq times)"
                            ;;
                        BEST_CHAIN:*)
                            local bc="${line#BEST_CHAIN:}"
                            echo "  2. Expected sequence: $bc"
                            ;;
                        TOP_CHAIN:*)
                            local tc="${line#TOP_CHAIN:}"
                            local tc_data=$(echo "$tc" | cut -d'|' -f1-2 --output-delimiter=' → ')
                            echo "  Most successful sequence: $tc_data"
                            ;;
                    esac
                done <<< "$best_path"
            fi
            ;;

        evidence)
            db_init
            inference_init
            local session="${1:-$INFERENCE_SESSION}"
            local ev=$(db_query "SELECT decision, reason, sources, created_at FROM evidence WHERE session_id='$session' ORDER BY created_at DESC LIMIT 20")
            if [ -n "$ev" ]; then
                echo "Evidence Log"
                echo "══════════════"
                while IFS='|' read -r decision reason sources created_at; do
                    echo ""
                    echo "  [$created_at] $decision"
                    echo "  Reason: $reason"
                    [ -n "$sources" ] && echo "  Sources: $(echo "$sources" | head -5)"
                done <<< "$ev"
            else
                echo "  No evidence for this session."
            fi
            ;;

        stats)
            db_init
            local ft="$1"
            if [ -n "$ft" ]; then
                echo "Tool Statistics for: $ft"
                echo "═══════════════════════════"
                local stats=$(db_stats_best_for "$ft" 20)
                if [ -z "$stats" ]; then
                    echo "  No data for '$ft'."
                else
                    printf "  %-20s %-25s %-10s %s\n" "Tool" "Technique" "Confidence" "Cases"
                    echo "  ─────────────────────────────────────────────────────"
                    while IFS='|' read -r tool technique conf count; do
                        [ -z "$tool" ] && continue
                        local cp=$(calc_pct "$conf" 2>/dev/null)
                        printf "  %-20s %-25s %-9s%% %d\n" "$tool" "$technique" "$cp" "$count"
                    done <<< "$stats"
                fi
            else
                db_stats_all | while IFS='|' read -r ft tool tech sc tc conf; do
                    [ -z "$ft" ] && continue
                    local cp=$(calc_pct "$conf" 2>/dev/null)
                    echo "  $ft → $tool ($tech): $sc/$tc success ($cp%)"
                done
            fi
            ;;

        connectors)
            echo "Available Connectors"
            echo "══════════════════════"
            connector_list_types
            ;;

        setup-auto-sync|cron)
            bash "${KNOWLEDGE_DIR}/setup_auto_sync.sh" cron
            ;;

        setup-login-sync|login)
            bash "${KNOWLEDGE_DIR}/setup_auto_sync.sh" login
            ;;

        stop-auto)
            bash "${KNOWLEDGE_DIR}/setup_auto_sync.sh" stop
            ;;

        auto-status|status)
            bash "${KNOWLEDGE_DIR}/setup_auto_sync.sh" status
            ;;

        auto-defaults)
            db_init
            add_default_sources
            sync_all 10
            ;;

        prune)
            db_init
            echo "Knowledge Base Maintenance"
            echo "═══════════════════════════"
            db_writeup_report_garbage
            local blocked=$(db_query "SELECT COUNT(*) FROM writeups WHERE summary LIKE '%Just a moment%'")
            local captcha=$(db_query "SELECT COUNT(*) FROM writeups WHERE summary LIKE '%captcha%' OR summary LIKE '%recaptcha%'")
            echo "  Blocked pages summary:"
            echo "    Cloudflare: $blocked"
            echo "    Captcha:    $captcha"
            ;;

        help|--help|-h)
            kbe_usage
            ;;

        *)
            kbe_usage
            ;;
    esac
}

import_single_file() {
    local f="$1"
    local url="file://$f"
    local name=$(basename "$f")

    if db_writeup_exists "$url"; then
        db_log "IMPORT" "Skipping existing: $name"
        return
    fi

    local content=$(cat "$f" 2>/dev/null)
    [ -z "$content" ] && { db_log "IMPORT" "Empty file: $name"; return; }

    local hash=$(echo "$content" | md5sum | cut -d' ' -f1)
    local existing=$(db_writeup_by_hash "$hash")
    [ -n "$existing" ] && { db_log "IMPORT" "Duplicate content: $name"; return; }

    local ext="${f##*.}"
    if [ "$ext" = "pdf" ]; then
        content=$(parse_pdf "$f" 2>/dev/null)
    elif [ "$ext" = "html" ]; then
        content=$(parse_html "$content" 2>/dev/null)
    fi

    local parsed=$(parse_writeup "$content" "$url" 2>/dev/null)
    local title=$(echo "$parsed" | grep "^TITLE:" | sed 's/^TITLE://')
    local category=$(echo "$parsed" | grep "^CATEGORY:" | sed 's/^CATEGORY://')
    local challenge=$(echo "$parsed" | grep "^CHALLENGE:" | sed 's/^CHALLENGE://')
    local pub_date=$(echo "$parsed" | grep "^DATE:" | sed 's/^DATE://')
    local summary=$(echo "$parsed" | grep "^SUMMARY:" | sed 's/^SUMMARY://')
    local writeup_body=$(echo "$parsed" | sed -n '/^---CONTENT---$/,$ p' | tail -n +2)

    [ -z "$title" ] && title="$name"

    # Relevance filter: skip if no tools/techniques match our modules
    if ! _writeup_is_relevant "$writeup_body" 2>/dev/null; then
        db_log "IMPORT" "Skipping irrelevant: $name"
        return
    fi

    db_writeup_insert "$title" "$challenge" "$category" "$url" "$hash" "$pub_date" "$summary"
    local wid=$(db_writeup_by_hash "$hash")

    if [ -n "$wid" ]; then
        import_knowledge "$wid" "$writeup_body"
        db_log "IMPORT" "Imported: $title"
    fi
}

# If called directly (not sourced), run
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    kbe_main "$@"
fi
