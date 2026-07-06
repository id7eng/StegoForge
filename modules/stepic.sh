MD_NAME="Stepic"
MD_DESC="Decode LSB data using stepic Python library (picoCTF 2025)"
MD_TYPES="png bmp"
MD_DEPS="python3"
MD_PRIORITY=36
MD_PRODUCES="stepic_data flag"

analyze_stepic() {
    local f="$1"
    header "Stepic" "Python stepic LSB Decoder"

    if ! run_cmd python3 -c "import stepic"; then
        info "stepic not installed (pip install stepic)"
        return
    fi

    export STEPIC_FILE="$f"
    local out=$(run_cmd python3 -c "
import os, stepic
from PIL import Image
try:
    im = Image.open(os.environ['STEPIC_FILE'])
    data = stepic.decode(im)
    if data.strip():
        print(data)
except Exception:
    pass
")
    unset STEPIC_FILE

    [ -n "$out" ] && emit "stepic_data" "Stepic data: $out"
}
