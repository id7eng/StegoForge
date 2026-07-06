MD_NAME="PNG CRC"
MD_DESC="Detect PNG IHDR CRC manipulation (wrong dimensions)"
MD_TYPES="png"
MD_DEPS="python3"
MD_PRIORITY=25
MD_PRODUCES="crc_fixed dims_found"

analyze_png_crc() {
    local f="$1"
    header "PNG CRC" "IHDR Dimension Check"

    local ihdr_hex=$(run_cmd xxd -s 8 -l 13 -p "$f")
    [ -z "$ihdr_hex" ] && { info "Not a valid PNG"; return; }

    local stored_crc=$(run_cmd xxd -s 29 -l 4 -p "$f")
    export PNGCRC_IHDR_HEX="$ihdr_hex"
    local computed_crc=$(run_cmd python3 -c "
import os, struct, zlib
data = bytes.fromhex(os.environ['PNGCRC_IHDR_HEX'])
crc = zlib.crc32(data) & 0xffffffff
print(f'{crc:08x}')
")
    unset PNGCRC_IHDR_HEX

    if [ "$stored_crc" = "$computed_crc" ]; then
        info "CRC OK"
        return
    fi

    $VERBOSE && warn "CRC MISMATCH! Stored: $stored_crc, Computed: $computed_crc"
    emit "crc_fixed" "PNG CRC mismatch detected"

    export PNGCRC_FILE="$f"
    while read line; do
        case "$line" in
            FOUND_HT:*) emit "dims_found" "Correct height = ${line#FOUND_HT:}" ;;
            FOUND_WD:*) emit "dims_found" "Correct width = ${line#FOUND_WD:}" ;;
            NOT_FOUND) info "Could not find correct dimensions" ;;
        esac
    done < <(run_cmd python3 -c "
import os, struct, zlib

with open(os.environ['PNGCRC_FILE'], 'rb') as f:
    data = bytearray(f.read())

ihdr_start = 8
orig_crc = data[29:33]
fixed_path = os.environ['PNGCRC_FILE'] + '.crc_fixed'

for h in range(1, 3000):
    data[ihdr_start+4:ihdr_start+8] = struct.pack('>I', h)
    crc = struct.pack('>I', zlib.crc32(bytes(data[ihdr_start:ihdr_start+13])) & 0xffffffff)
    if crc == orig_crc:
        print(f'FOUND_HT:{h}')
        with open(fixed_path, 'wb') as out:
            out.write(data)
        exit(0)

for w in range(1, 3000):
    data[ihdr_start:ihdr_start+4] = struct.pack('>I', w)
    data[ihdr_start+4:ihdr_start+8] = data[ihdr_start+4:ihdr_start+8]
    crc = struct.pack('>I', zlib.crc32(bytes(data[ihdr_start:ihdr_start+13])) & 0xffffffff)
    if crc == orig_crc:
        print(f'FOUND_WD:{w}')
        with open(fixed_path, 'wb') as out:
            out.write(data)
        exit(0)

print('NOT_FOUND')
")
    unset PNGCRC_FILE

    [ -f "$f.crc_fixed" ] && {
        cp "$f.crc_fixed" "${OUTDIR}/repaired/"
        $VERBOSE && info "Fixed PNG → ${OUTDIR}/repaired/"
    }
}
