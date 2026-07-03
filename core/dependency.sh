doctor() {
    echo -e "${C}╔══════════════════════════════════════════════╗${N}"
    echo -e "${C}║     ${W}StegoForge v${VERSION}${C} - Dependency Check    ║${N}"
    echo -e "${C}╚══════════════════════════════════════════════╝${N}"
    echo ""

    local core_deps=("bash" "file" "xxd" "strings" "md5sum" "sha256sum" "jq")
    local opt_deps=("exiftool" "binwalk" "foremost" "steghide" "zsteg" "fcrackzip" "pngcheck" "getfattr")
    local py_deps=("python3")

    echo -e "${BOLD}Core Required:${N}"
    local all_ok=true
    for dep in "${core_deps[@]}"; do
        if command -v "$dep" &>/dev/null; then
            echo -e "  ${G}[OK]${N} $dep"
        else
            echo -e "  ${R}[X]${N} $dep"
            all_ok=false
        fi
    done

    echo ""
    echo -e "${BOLD}Optional Tools:${N}"
    for dep in "${opt_deps[@]}"; do
        if command -v "$dep" &>/dev/null; then
            echo -e "  ${G}[OK]${N} $dep"
        else
            echo -e "  ${Y}[--]${N} $dep"
            case "$dep" in
                exiftool) echo -e "     ${DIM}apt install exiftool${N}" ;;
                binwalk)  echo -e "     ${DIM}apt install binwalk${N}" ;;
                foremost) echo -e "     ${DIM}apt install foremost${N}" ;;
                steghide) echo -e "     ${DIM}apt install steghide${N}" ;;
                zsteg)    echo -e "     ${DIM}gem install zsteg${N}" ;;
                fcrackzip) echo -e "     ${DIM}apt install fcrackzip${N}" ;;
                getfattr) echo -e "     ${DIM}apt install getfattr${N}" ;;
                pngcheck) echo -e "     ${DIM}apt install pngcheck${N}" ;;
            esac
        fi
    done
    command -v convert &>/dev/null && echo -e "  ${G}[OK]${N} convert (ImageMagick)" || echo -e "  ${Y}[--]${N} convert (apt install imagemagick)"
    command -v identify &>/dev/null && echo -e "  ${G}[OK]${N} identify (ImageMagick)" || echo -e "  ${Y}[--]${N} identify (apt install imagemagick)"

    echo ""
    echo -e "${BOLD}Python Modules:${N}"
    python3 -c "from PIL import Image; print('  [OK] PIL')" 2>/dev/null || echo -e "  ${Y}[--]${N} PIL (pip install pillow)"
    python3 -c "from pyzbar.pyzbar import decode; print('  [OK] pyzbar')" 2>/dev/null || echo -e "  ${Y}[--]${N} pyzbar (pip install pyzbar)"
    python3 -c "import scipy; print('  [OK] scipy')" 2>/dev/null || echo -e "  ${Y}[--]${N} scipy (pip install scipy)"
    python3 -c "import matplotlib; print('  [OK] matplotlib')" 2>/dev/null || echo -e "  ${Y}[--]${N} matplotlib (pip install matplotlib)"

    echo ""
    echo -e "${BOLD}Modules: ${G}${#MODULE_NAMES[@]}${N} loaded${N}"
    echo ""
    echo -e "${BOLD}Config:${N}"
    [ -f "${CONFIG_DIR}/flag_patterns.conf" ] && echo -e "  ${G}[OK]${N} flag_patterns.conf ($(grep -cEv '^#|^$' "${CONFIG_DIR}/flag_patterns.conf" 2>/dev/null) patterns)" || echo -e "  ${Y}[--]${N} flag_patterns.conf"
    [ -f "${CONFIG_DIR}/passwords.conf" ] && echo -e "  ${G}[OK]${N} passwords.conf ($(wc -l < "${CONFIG_DIR}/passwords.conf" 2>/dev/null) entries)" || echo -e "  ${Y}[--]${N} passwords.conf"

    $all_ok || echo -e "\n${Y}[!]${N} Some core dependencies missing. Install them first."
    exit 0
}
