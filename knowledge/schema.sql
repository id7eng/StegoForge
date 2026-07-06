-- StegoForge Knowledge Base Schema

CREATE TABLE IF NOT EXISTS sources (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    type TEXT NOT NULL CHECK(type IN ('github','blog','local','pdf','rss','manual','ctftime')),
    url TEXT,
    enabled INTEGER DEFAULT 1,
    sync_interval INTEGER DEFAULT 86400,
    last_sync TEXT,
    created_at TEXT DEFAULT (datetime('now')),
    updated_at TEXT DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS writeups (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT,
    challenge_name TEXT,
    category TEXT,
    url TEXT UNIQUE,
    content_hash TEXT UNIQUE,
    publish_date TEXT,
    fetched_at TEXT DEFAULT (datetime('now')),
    language TEXT DEFAULT 'en',
    summary TEXT,
    UNIQUE(url)
);

CREATE TABLE IF NOT EXISTS knowledge (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    writeup_id INTEGER REFERENCES writeups(id) ON DELETE CASCADE,
    knowledge_type TEXT NOT NULL CHECK(knowledge_type IN (
        'tool','technique','file_type','command','password','flag_pattern',
        'encoding','signature','indicator','os','note','category'
    )),
    key TEXT NOT NULL,
    value TEXT NOT NULL,
    confidence REAL DEFAULT 1.0,
    context TEXT,
    created_at TEXT DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS workflows (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    writeup_id INTEGER REFERENCES writeups(id) ON DELETE CASCADE,
    step_order INTEGER NOT NULL,
    action TEXT,
    tool TEXT,
    parameters TEXT,
    result TEXT,
    success INTEGER DEFAULT 1,
    created_at TEXT DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS evidence (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT NOT NULL,
    decision TEXT NOT NULL,
    reason TEXT NOT NULL,
    sources TEXT,
    created_at TEXT DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS sync_log (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    source_id INTEGER REFERENCES sources(id),
    status TEXT CHECK(status IN ('running','success','failed')),
    items_found INTEGER DEFAULT 0,
    items_imported INTEGER DEFAULT 0,
    error_msg TEXT,
    started_at TEXT,
    finished_at TEXT
);

CREATE TABLE IF NOT EXISTS statistics (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    file_type TEXT NOT NULL,
    tool TEXT,
    technique TEXT,
    success_count INTEGER DEFAULT 0,
    total_count INTEGER DEFAULT 0,
    confidence REAL GENERATED ALWAYS AS (
        CASE WHEN total_count > 0
        THEN CAST(success_count AS REAL) / total_count
        ELSE 0 END
    ) STORED,
    last_updated TEXT DEFAULT (datetime('now')),
    UNIQUE(file_type, tool, technique)
);

CREATE INDEX IF NOT EXISTS idx_knowledge_type ON knowledge(knowledge_type);
CREATE INDEX IF NOT EXISTS idx_knowledge_key ON knowledge(key);
CREATE INDEX IF NOT EXISTS idx_knowledge_writeup ON knowledge(writeup_id);
CREATE INDEX IF NOT EXISTS idx_workflows_writeup ON workflows(writeup_id);
CREATE INDEX IF NOT EXISTS idx_statistics_ft ON statistics(file_type);
CREATE INDEX IF NOT EXISTS idx_writeups_category ON writeups(category);
CREATE INDEX IF NOT EXISTS idx_writeups_challenge ON writeups(challenge_name);
CREATE INDEX IF NOT EXISTS idx_evidence_session ON evidence(session_id);
CREATE INDEX IF NOT EXISTS idx_sync_log_source ON sync_log(source_id);
