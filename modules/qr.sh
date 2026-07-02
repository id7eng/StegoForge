MD_NAME="QR"
MD_DESC="QR code detection"
MD_TYPES="jpg jpeg png bmp gif"
MD_DEPS="python3-pil python3-pyzbar"
MD_PRIORITY=35
MD_PRODUCES="qr_data"

analyze_qr() {
    local f="$1"
    header "QR" "QR Code Detection"
    python3 -c "
from PIL import Image
try:
    from pyzbar.pyzbar import decode
    codes = decode(Image.open('$f'))
    if codes:
        for c in codes: print('QR:' + c.data.decode())
    else: print('NONE')
except: print('NONE')
" 2>/dev/null | while read line; do
        case "$line" in
            QR:*) emit "qr_data" "${line#QR:}" ;;
        esac
    done
}
