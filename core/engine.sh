# ─────────────────────────────────────────────
# StegoForge — engine.sh (entry point)
# ─────────────────────────────────────────────
[ -z "$TOOL_DIR" ] && {
    SELF="${BASH_SOURCE[0]}"
    while [ -h "$SELF" ]; do SELF="$(readlink "$SELF")"; done
    TOOL_DIR="$(cd -P "$(dirname "$SELF")/.." && pwd)"
}
CORE_DIR="${TOOL_DIR}/core"
MODULES_DIR="${TOOL_DIR}/modules"
CONFIG_DIR="${TOOL_DIR}/config"
OUTPUT_DIR="${TOOL_DIR}/output"

source "${CORE_DIR}/logger.sh"
source "${CORE_DIR}/utils.sh"
source "${CORE_DIR}/flags.sh"
source "${CORE_DIR}/dependency.sh"
source "${CORE_DIR}/docker.sh"
source "${CORE_DIR}/priority.sh"
source "${CORE_DIR}/confidence.sh"
source "${CORE_DIR}/decision.sh"
source "${CORE_DIR}/module_api.sh"
source "${CORE_DIR}/orchestrator.sh"
source "${CORE_DIR}/reporter.sh"
source "${CORE_DIR}/cli.sh"

KNOWLEDGE_DIR="${TOOL_DIR}/knowledge"

PIPELINE_CONF="${CONFIG_DIR}/pipeline.conf"
PIPELINE_RULES=()
PIPELINE_SEEN=()

VERSION="2.0.0"
QUIET=true; DOCKER_MODE=false
OUTDIR=""; RECURSIVE=false; VERBOSE=false; VERBOSE_CMD=false; JSON=false; SUMMARY=false; READONLY=false
REPORT_FILE=""; TARGET=""; WORDLIST=""
FINDINGS=()
EMITTED=()
ANALYZE_THIS=""
SMART_WL=""

declare -a MODULE_NAMES MODULE_PRIORITY_ORDER
declare -A MODULE_DISPLAY MODULE_TYPES MODULE_DEPS MODULE_PRIORITY MODULE_PRODUCES MODULE_TRIGGERS
