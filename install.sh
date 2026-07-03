#!/bin/bash
echo "=============================="
echo " StegoForge v1.3.2 - Installer"
echo "=============================="
echo ""

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
echo "[*] Checking dependencies..."
for dep in bash file xxd strings md5sum sha256sum jq; do
    command -v "$dep" &>/dev/null || echo "  [WARN] $dep missing (core required)"
done

echo ""
echo "[*] Optional tools:"
for dep in exiftool binwalk foremost steghide zsteg fcrackzip pngcheck getfattr; do
    command -v "$dep" &>/dev/null && echo "  [OK] $dep" || echo "  [--] $dep"
done
for dep in convert identify; do
    command -v "$dep" &>/dev/null && echo "  [OK] $dep (ImageMagick)" || echo "  [--] $dep"
done

echo ""
INSTALL_DIR="/usr/local/bin"
if [ -w "$INSTALL_DIR" ] || [ "$(id -u)" -eq 0 ]; then
    ln -sf "$SCRIPT_DIR/stegoforge" "$INSTALL_DIR/stegoforge"
    echo "[OK] Installed to $INSTALL_DIR/stegoforge"
else
    echo "[!] Need root:"
    echo "    sudo ln -sf $SCRIPT_DIR/stegoforge $INSTALL_DIR/stegoforge"
    echo "    Or use: ./stegoforge"
fi

echo ""
echo "=============================="
echo " Doctor: stegoforge --doctor"
echo " Modules: stegoforge --list"
echo "=============================="
