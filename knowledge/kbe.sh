#!/bin/bash
# ─────────────────────────────────────────────
# StegoForge Knowledge Base Engine (KBE)
# ─────────────────────────────────────────────
# Usage: stegoforge knowledge <command> [options]
#
# Commands:
#   init              Initialize database
#   sync              Sync all sources
#   sync-source <id>  Sync specific source
#   add-source        Add a new source
#   list-sources      List all sources
#   info              Show KB statistics
#   search <term>     Search knowledge base
#   suggest <file>    Suggest workflow for a file
#   evidence          Show reasoning evidence
#   stats             Show tool statistics
#   connectors        List available connectors

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
    echo "  sync-source <id>        Sync specific source"
    echo "  add-source               Add a new knowledge source"
    echo "  list-sources             List all sources"
    echo "  remove-source <id>       Remove a source"
    echo "  setup-auto-sync          Set up daily automatic sync (cron)"
    echo "  setup-login-sync         Set up sync on login"
    echo "  stop-auto                Stop automatic sync"
    echo "  auto-status              Show auto-sync status"
    echo "  info                     Show KB statistics"
    echo "  search <term>            Search the knowledge base"
    echo "  suggest <file>           Suggest analysis workflow for a file"
    echo "  evidence [session]       Show reasoning evidence"
    echo "  stats [file_type]        Show tool success statistics"
    echo "  connectors               List available connector types"
    echo "  auto-defaults            Add all default built-in sources"
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
            local auto_flag="$1"
            if [ "$auto_flag" = "--auto" ]; then
                db_log "KB" "Adding default sources before sync..."
                add_default_sources
            fi
            sync_all
            ;;

        sync-source)
            local id="$1"
            [ -z "$id" ] && { echo "Usage: stegoforge knowledge sync-source <id>"; exit 1; }
            db_init
            sync_source_by_id "$id"
            ;;

        add-source)
            echo "Enter source name:"
            read -r name
            echo "Enter source type (github/local):"
            read -r stype
            echo "Enter source URL:"
            read -r url
            echo "Sync interval in seconds (default 86400 = daily):"
            read -r interval
            interval="${interval:-86400}"
            db_init
            sync_add_source "$name" "$stype" "$url" "$interval"
            ;;

        list-sources)
            db_init
            local list=$(db_source_list)
            if [ -z "$list" ]; then
                echo "  No sources configured."
                echo "  Add one with: stegoforge knowledge add-source"
            else
                printf "  %-4s %-20s %-10s %-30s %-8s %s\n" "ID" "Name" "Type" "URL" "Active" "Last Sync"
                echo "  ─────────────────────────────────────────────────────────────────────"
                while IFS='|' read -r id name stype url enabled last_sync; do
                    [ -z "$id" ] && continue
                    local status="✓"
                    [ "$enabled" = "0" ] && status="✗"
                    last_sync="${last_sync:---}"
                    printf "  %-4s %-20s %-10s %-30s %-8s %s\n" "$id" "$name" "$stype" "$url" "$status" "$last_sync"
                done <<< "$list"
            fi
            ;;

        remove-source)
            local id="$1"
            [ -z "$id" ] && { echo "Usage: stegoforge knowledge remove-source <id>"; exit 1; }
            db_exec "DELETE FROM sources WHERE id=$id"
            db_log "KBE" "Source #$id removed"
            ;;

        info)
            db_init
            echo "📊 Knowledge Base Statistics"
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
                echo "🔍 Search results for: $term"
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
            echo "🔎 Knowledge-Based Analysis for: $(basename "$file")"
            echo "══════════════════════════════════════════"
            echo "  Type: $ftype"
            echo ""

            local analysis=$(inference_analyze "$file" "$ftype")
            local reasoning=$(echo "$analysis" | grep "^REASONING:" | sed 's/^REASONING://')

            if [ -n "$reasoning" ]; then
                echo "📋 Analysis Reasoning:"
                echo "$reasoning"
            else
                echo "  ⚠ No knowledge data for this file type yet."
                echo "  Run 'stegoforge knowledge sync' to build the knowledge base."
            fi
            ;;

        evidence)
            db_init
            inference_init
            local session="${1:-$INFERENCE_SESSION}"
            inference_evidence "$session"
            ;;

        stats)
            db_init
            local ft="$1"
            if [ -n "$ft" ]; then
                echo "📈 Tool Statistics for: $ft"
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
                    echo "  $ft → $tool ($tech): $sc/$tc نجاح ($cp%)"
                done
            fi
            ;;

        connectors)
            echo "📎 Available Connectors"
            echo "══════════════════════"
            connector_list_types
            ;;

        auto-defaults)
            db_init
            add_default_sources
            sync_all
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

        help|--help|-h)
            kbe_usage
            ;;

        *)
            kbe_usage
            ;;
    esac
}

# If called directly (not sourced), run
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    kbe_main "$@"
fi
