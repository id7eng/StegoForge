# ─────────────────────────────────────────────
# StegoForge Knowledge Base — Database Layer
# ─────────────────────────────────────────────

KNOWLEDGE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DB_PATH="${KNOWLEDGE_DIR}/knowledge.db"

db_init() {
    sqlite3 "$DB_PATH" < "${KNOWLEDGE_DIR}/schema.sql" 2>/dev/null
    db_log "DB" "Database initialized at $DB_PATH"
}

db_query() {
    sqlite3 -separator '|' "$DB_PATH" "$1" 2>/dev/null
}

db_exec() {
    sqlite3 "$DB_PATH" "$1" 2>/dev/null
}

db_log() {
    local level="$1" msg="$2"
    echo "  [KB:$level] $msg" >&2
}

# ─── Writeups ───

db_writeup_exists() {
    local url="$1"
    local c=$(db_query "SELECT COUNT(*) FROM writeups WHERE url='$(echo "$url" | sed "s/'/''/g")'")
    [ "$c" -gt 0 ]
}

db_writeup_by_hash() {
    local hash="$1"
    db_query "SELECT id FROM writeups WHERE content_hash='$hash'" | head -1
}

db_writeup_insert() {
    local title="$1" challenge="$2" category="$3" url="$4" hash="$5" pub_date="$6" summary="$7" lang="${8:-en}"
    title=$(echo "$title" | sed "s/'/''/g")
    challenge=$(echo "$challenge" | sed "s/'/''/g")
    category=$(echo "$category" | sed "s/'/''/g")
    url=$(echo "$url" | sed "s/'/''/g")
    summary=$(echo "$summary" | sed "s/'/''/g")
    [ -z "$pub_date" ] && pub_date=$(date +%Y-%m-%d)
    db_exec "INSERT OR IGNORE INTO writeups(title,challenge_name,category,url,content_hash,publish_date,summary,language) VALUES('$title','$challenge','$category','$url','$hash','$pub_date','$summary','$lang')"
}

# ─── Knowledge ───

db_knowledge_insert() {
    local writeup_id="$1" ktype="$2" key="$3" value="$4" confidence="${5:-1.0}" context="${6:-}"
    key=$(echo "$key" | sed "s/'/''/g")
    value=$(echo "$value" | sed "s/'/''/g")
    context=$(echo "$context" | sed "s/'/''/g")
    db_exec "INSERT INTO knowledge(writeup_id,knowledge_type,key,value,confidence,context) VALUES($writeup_id,'$ktype','$key','$value',$confidence,'$context')"
}

db_knowledge_search() {
    local term="$1"
    db_query "SELECT k.knowledge_type, k.key, k.value, k.confidence, w.challenge_name FROM knowledge k JOIN writeups w ON k.writeup_id = w.id WHERE k.key LIKE '%$term%' OR k.value LIKE '%$term%' ORDER BY k.confidence DESC LIMIT 30"
}

db_knowledge_by_type() {
    local ktype="$1" limit="${2:-20}"
    db_query "SELECT key, value, confidence, COUNT(*) as freq FROM knowledge WHERE knowledge_type='$ktype' GROUP BY key, value ORDER BY freq DESC, confidence DESC LIMIT $limit"
}

# ─── Workflows ───

db_workflow_insert() {
    local writeup_id="$1" step="$2" action="$3" tool="$4" params="$5" result="$6" success="${7:-1}"
    action=$(echo "$action" | sed "s/'/''/g")
    tool=$(echo "$tool" | sed "s/'/''/g")
    params=$(echo "$params" | sed "s/'/''/g")
    result=$(echo "$result" | sed "s/'/''/g")
    db_exec "INSERT INTO workflows(writeup_id,step_order,action,tool,parameters,result,success) VALUES($writeup_id,$step,'$action','$tool','$params','$result',$success)"
}

db_workflows_for_filetype() {
    local file_type="$1" limit="${2:-10}"
    local ft_lower=$(echo "$file_type" | tr '[:upper:]' '[:lower:]')
    db_query "SELECT DISTINCT wf.action, wf.tool, wf.parameters, COUNT(*) as freq FROM workflows wf JOIN knowledge k ON wf.writeup_id = k.writeup_id AND k.knowledge_type='file_type' AND LOWER(k.value)='$ft_lower' GROUP BY wf.tool, wf.action ORDER BY freq DESC LIMIT $limit"
}

db_workflow_chains() {
    local file_type="$1" limit="${2:-5}"
    local ft_lower=$(echo "$file_type" | tr '[:upper:]' '[:lower:]')
    db_query "SELECT w1.tool as tool1, w1.action as action1, w2.tool as tool2, w2.action as action2, COUNT(*) as freq FROM workflows w1 JOIN workflows w2 ON w1.writeup_id = w2.writeup_id AND w2.step_order = w1.step_order + 1 WHERE w1.tool != '' AND w2.tool != '' AND w1.writeup_id IN (SELECT DISTINCT k.writeup_id FROM knowledge k WHERE k.knowledge_type='file_type' AND LOWER(k.value)='$ft_lower') GROUP BY w1.tool, w2.tool ORDER BY freq DESC LIMIT $limit"
}

db_workflow_top_tools() {
    local file_type="$1" limit="${2:-5}"
    local ft_lower=$(echo "$file_type" | tr '[:upper:]' '[:lower:]')
    db_query "SELECT wf.tool, COUNT(*) as freq FROM workflows wf WHERE wf.writeup_id IN (SELECT DISTINCT k.writeup_id FROM knowledge k WHERE k.knowledge_type='file_type' AND LOWER(k.value)='$ft_lower') GROUP BY wf.tool ORDER BY freq DESC LIMIT $limit"
}

# ─── Statistics ───

db_stats_update() {
    local file_type="$1" tool="$2" technique="$3" success="${4:-1}"
    file_type=$(echo "$file_type" | sed "s/'/''/g" | tr '[:upper:]' '[:lower:]')
    # Normalize aliases
    case "$file_type" in
        jpg|jpeg) file_type="jpeg" ;;
    esac
    tool=$(echo "$tool" | sed "s/'/''/g")
    technique=$(echo "$technique" | sed "s/'/''/g")
    local exists=$(db_query "SELECT COUNT(*) FROM statistics WHERE file_type='$file_type' AND tool='$tool' AND technique='$technique'")
    if [ "$exists" -gt 0 ]; then
        if [ "$success" = "1" ]; then
            db_exec "UPDATE statistics SET success_count=success_count+1, total_count=total_count+1, last_updated=datetime('now') WHERE file_type='$file_type' AND tool='$tool' AND technique='$technique'"
        else
            db_exec "UPDATE statistics SET total_count=total_count+1, last_updated=datetime('now') WHERE file_type='$file_type' AND tool='$tool' AND technique='$technique'"
        fi
    else
        local sc=0; [ "$success" = "1" ] && sc=1
        db_exec "INSERT INTO statistics(file_type,tool,technique,success_count,total_count) VALUES('$file_type','$tool','$technique',$sc,1)"
    fi
}

db_stats_worst_for() {
    local file_type="$1" limit="${2:-5}"
    local ft_query="file_type='$file_type'"
    case "$file_type" in
        jpg|jpeg) ft_query="(file_type='jpg' OR file_type='jpeg')" ;;
    esac
    db_query "SELECT tool, technique, confidence, total_count FROM statistics WHERE $ft_query AND total_count > 2 ORDER BY confidence ASC, total_count DESC LIMIT $limit"
}

db_stats_best_for() {
    local file_type="$1" limit="${2:-10}"
    # Handle type aliases
    local ft_query="file_type='$file_type'"
    case "$file_type" in
        jpg|jpeg) ft_query="(file_type='jpg' OR file_type='jpeg')" ;;
        png|png) ;;
    esac
    db_query "SELECT tool, technique, confidence, total_count FROM statistics WHERE $ft_query AND total_count > 0 ORDER BY confidence DESC, total_count DESC LIMIT $limit"
}

db_stats_all() {
    db_query "SELECT file_type, tool, technique, success_count, total_count, confidence FROM statistics ORDER BY confidence DESC LIMIT 50"
}

# ─── Sources ───

db_source_add() {
    local name="$1" stype="$2" url="$3" interval="${4:-86400}"
    name=$(echo "$name" | sed "s/'/''/g")
    url=$(echo "$url" | sed "s/'/''/g")
    db_exec "INSERT OR IGNORE INTO sources(name,type,url,sync_interval) VALUES('$name','$stype','$url',$interval)"
}

db_source_list() {
    db_query "SELECT id, name, type, url, enabled, last_sync FROM sources ORDER BY id"
}

db_source_get() {
    local id="$1"
    db_query "SELECT * FROM sources WHERE id=$id" | head -1
}

# ─── Sync Log ───

db_sync_start() {
    local source_id="$1"
    db_exec "INSERT INTO sync_log(source_id,status,started_at) VALUES($source_id,'running',datetime('now'))"
    db_query "SELECT id FROM sync_log WHERE source_id=$source_id ORDER BY id DESC LIMIT 1" | head -1
}

db_sync_finish() {
    local log_id="$1" status="$2" found="$3" imported="$4" error="${5:-}"
    db_exec "UPDATE sync_log SET status='$status', items_found=$found, items_imported=$imported, error_msg='$error', finished_at=datetime('now') WHERE id=$log_id"
    db_exec "UPDATE sources SET last_sync=datetime('now') WHERE id=(SELECT source_id FROM sync_log WHERE id=$log_id)"
}

# ─── Evidence ───

db_evidence_add() {
    local session="$1" decision="$2" reason="$3" sources="${4:-}"
    decision=$(echo "$decision" | sed "s/'/''/g")
    reason=$(echo "$reason" | sed "s/'/''/g")
    sources=$(echo "$sources" | sed "s/'/''/g")
    db_exec "INSERT INTO evidence(session_id,decision,reason,sources) VALUES('$session','$decision','$reason','$sources')"
}

# ─── Advanced Page Detection ───

_db_content_is_captcha() {
    local content="$1"
    echo "$content" | grep -qiE '(recaptcha|cf-turnstile|hcaptcha|g-recaptcha|captcha|challenge-platform)' >/dev/null 2>&1
}

_db_content_is_login() {
    local content="$1"
    echo "$content" | grep -qiE '(login|sign.in|signin|log.in|log_in|authenticate|please.log)' >/dev/null 2>&1
    local has_form=$(echo "$content" | grep -ci '<input.*type.?=.?["'"'"']password['"''"']' 2>/dev/null)
    [ "$has_form" -gt 0 ] && return 0
    return 1
}

_db_content_is_404() {
    local content="$1"
    echo "$content" | grep -qiE '(404|not.found|page.not.found|doesn.t.exist|couldn.t.be.found)' >/dev/null 2>&1
}

_db_content_is_blocked() {
    local content="$1"
    _db_writeup_is_unfetchable "$content" && return 0
    _db_content_is_captcha "$content" && return 0
    _db_content_is_login "$content" && return 0
    _db_content_is_404 "$content" && return 0
    return 1
}

# ─── Maintenance ───

_db_writeup_is_unfetchable() {
    local summary="$1"
    echo "$summary" | grep -qi "Just a moment" >/dev/null 2>&1
}

db_writeup_report_garbage() {
    local count_bad=$(db_query "SELECT COUNT(*) FROM writeups WHERE category='unknown'")
    local count_cloudflare=$(db_query "SELECT COUNT(*) FROM writeups WHERE summary LIKE '%Just a moment%'")
    local count_total=$(db_query "SELECT COUNT(*) FROM writeups")
    echo "  [KB] Writeups: $count_total total, $count_bad unknown category, $count_cloudflare Cloudflare-blocked"
}

# ─── Stats ───

db_stats_overview() {
    local w_count=$(db_query "SELECT COUNT(*) FROM writeups" | head -1)
    local k_count=$(db_query "SELECT COUNT(*) FROM knowledge" | head -1)
    local wf_count=$(db_query "SELECT COUNT(*) FROM workflows" | head -1)
    local s_count=$(db_query "SELECT COUNT(*) FROM sources" | head -1)
    local ft_count=$(db_query "SELECT DISTINCT file_type FROM statistics WHERE total_count > 0" | head -1)
    echo "Writeups: $w_count"
    echo "Knowledge entries: $k_count"
    echo "Workflows: $wf_count"
    echo "Sources: $s_count"
    echo "File types with data: $ft_count"
}
