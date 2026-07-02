MD_NAME="Stepic"
MD_DESC="Decode LSB data using stepic Python library (picoCTF 2025)"
MD_TYPES="png bmp"
MD_DEPS="python3"
MD_PRIORITY=36
MD_PRODUCES="stepic_data flag"

analyze_stepic() {
    local f="$1"
    header "Stepic" "Python stepic LSB Decoder"

    if ! python3 -c "import stepic" 2>/dev/null; then
        info "stepic not installed (pip install stepic)"
        return
    fi

    local out=$(python3 -c "
import stepic
from PIL import Image
try:
    im = Image.open('$f')
    data = stepic.decode(im)
    if data.strip():
        print(data)
except Exception:
    pass
" 2>/dev/null)

    [ -n "$out" ] && emit "stepic_data" "Stepic data: $out"
}
