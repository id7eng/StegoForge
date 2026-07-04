#!/bin/bash
# ─────────────────────────────────────────────
# Auto-Sync Setup — تجعل stegoforge يحدث نفسه تلقائياً
# ─────────────────────────────────────────────

TOOL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
KBE="${TOOL_DIR}/knowledge/kbe.sh"
SYNC_LOG="${TOOL_DIR}/knowledge/auto_sync.log"

setup_cron() {
    echo "🔧 تجهيز التحديث التلقائي اليومي..."
    echo ""

    # اختيار وقت التحديث
    echo "اختر وقت التحديث اليومي (HH:MM بصيغة 24 ساعة):"
    echo "  [1] 03:00 (3 الصبح) — recommended"
    echo "  [2] 12:00 (الظهر)"
    echo "  [3] 18:00 (6 المساء)"
    echo "  [4] أكتب وقت مخصص"
    read -r choice

    case "$choice" in
        1) HOUR=3; MIN=0 ;;
        2) HOUR=12; MIN=0 ;;
        3) HOUR=18; MIN=0 ;;
        4) 
            echo "اكتب الوقت (HH:MM):"
            read -r custom_time
            HOUR=$(echo "$custom_time" | cut -d: -f1)
            MIN=$(echo "$custom_time" | cut -d: -f2)
            ;;
        *) HOUR=3; MIN=0 ;;
    esac

    # حذف أي مهمة سابقة لنفس الأداة
    (crontab -l 2>/dev/null | grep -v "stegoforge.*knowledge.*sync" | grep -v "stegoforge_kb_autosync") | crontab - 2>/dev/null

    # إضافة المهمة الجديدة
    local cron_line="${MIN} ${HOUR} * * * cd ${TOOL_DIR} && bash ${KBE} sync --auto >> ${SYNC_LOG} 2>&1"
    (crontab -l 2>/dev/null; echo "$cron_line") | crontab - 2>/dev/null

    echo ""
    echo "✅ تم !"
    echo "   الأداة ستتحدث يومياً الساعة ${HOUR}:${MIN}"
    echo "   السجل: ${SYNC_LOG}"
    echo ""
    echo "   لعرض السجل:"
    echo "     cat ${SYNC_LOG}"
    echo ""
    echo "   لإيقاف التحديث التلقائي:"
    echo "     stegoforge knowledge stop-auto"
}

setup_login() {
    echo "🔧 تجهيز التحديث عند تشغيل الجهاز..."
    echo ""

    local rc_file="$HOME/.bashrc"
    local marker="# --- StegoForge Auto-Sync ---"

    # حذف الإضافة القديمة إن وجدت
    sed -i "/$marker/,/---/d" "$rc_file" 2>/dev/null

    # إضافة سطر التشغيل
    cat >> "$rc_file" << EOF

${marker}
if [ -f "${TOOL_DIR}/stegoforge" ]; then
    (bash ${KBE} sync --auto >> ${SYNC_LOG} 2>&1) &
fi
# ---
EOF

    echo "✅ تم !"
    echo "   الأداة ستتحدث تلقائياً كل ما تشغل اللابتوب"
    echo "   السجل: ${SYNC_LOG}"
    echo ""
    echo "   لعرض آخر تحديث:"
    echo "     tail -20 ${SYNC_LOG}"
}

setup_desktop() {
    echo "🔧 تجهيز تحديث عند فتح اللابتوب..."
    local autostart_dir="$HOME/.config/autostart"
    mkdir -p "$autostart_dir"

    cat > "$autostart_dir/stegoforge-sync.desktop" << EOF
[Desktop Entry]
Type=Application
Name=StegoForge Knowledge Sync
Comment=Auto-sync stegoforge knowledge base on login
Exec=bash ${KBE} sync --auto >> ${SYNC_LOG} 2>&1
Terminal=false
X-GNOME-Autostart-enabled=true
EOF

    chmod +x "$autostart_dir/stegoforge-sync.desktop"
    echo "✅ تم ! الأداة ستتحدث تلقائياً عند فتح اللابتوب."
}

stop_auto() {
    echo "🛑 إيقاف التحديث التلقائي..."
    (crontab -l 2>/dev/null | grep -v "stegoforge.*knowledge.*sync" | grep -v "stegoforge_kb_autosync") | crontab - 2>/dev/null
    echo "✅ تم إيقاف التحديث التلقائي."
}

show_status() {
    echo "📋 حالة التحديث التلقائي:"
    echo ""
    if crontab -l 2>/dev/null | grep -qi "stegoforge\|kbe.sh\|knowledge.*sync"; then
        local cron_line=$(crontab -l 2>/dev/null | grep "stegoforge")
        echo "  ✅ مفعّل (Cron job)"
        echo "  ⏰ $cron_line"
    else
        echo "  ❌ غير مفعّل"
    fi
    echo ""
    if [ -f "$SYNC_LOG" ]; then
        local last=$(tail -1 "$SYNC_LOG" 2>/dev/null)
        echo "  آخر تحديث: $last"
    fi
}

# ─── Main ───
case "$1" in
    cron|daily)    setup_cron ;;
    login)         setup_login ;;
    desktop|gui)   setup_desktop ;;
    stop)          stop_auto ;;
    status)        show_status ;;
    *)
        echo "StegoForge — إعداد التحديث التلقائي"
        echo ""
        echo "الاستخدام:"
        echo "  bash knowledge/setup_auto_sync.sh cron     ← تحديث يومي بالوقت اللي تحدده"
        echo "  bash knowledge/setup_auto_sync.sh login     ← تحديث كل ما تشغل الجهاز"
        echo "  bash knowledge/setup_auto_sync.sh status    ← عرض حالة التحديث"
        echo "  bash knowledge/setup_auto_sync.sh stop      ← إيقاف التحديث"
        ;;
esac
