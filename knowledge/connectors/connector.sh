# ─────────────────────────────────────────────
# StegoForge Knowledge — Connector Interface
# ─────────────────────────────────────────────
# Each connector must implement:
#   discover(source_id, source_url)  → prints writeup URLs/IDs
#   fetch(source_id, source_url, item_url)  → prints writeup content
#   name()  → prints connector name

connector_source_type=""

connector_run() {
    local source_id="$1" source_type="$2" source_url="$3" action="${4:-discover}"
    local connector="${KNOWLEDGE_DIR}/connectors/${source_type}.sh"
    if [ ! -f "$connector" ]; then
        db_log "ERROR" "No connector for type: $source_type"
        return 1
    fi
    source "$connector"
    case "$action" in
        discover) discover "$source_id" "$source_url" ;;
        fetch)    fetch "$source_id" "$source_url" "$5" ;;
        name)     name ;;
    esac
}

connector_list_types() {
    for c in "$KNOWLEDGE_DIR"/connectors/*.sh; do
        [ "$(basename "$c")" = "connector.sh" ] && continue
        local name=$(source "$c" 2>/dev/null; name 2>/dev/null)
        local base=$(basename "$c" .sh)
        echo "  $base → $name"
    done
}
