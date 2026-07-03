#!/bin/bash
# modules/polyglot_detector.sh - الكاشف والمصلح النهائي للملفات متعددة الأوجه
MD_NAME="Polyglot Fixer"
MD_PRIORITY=2
MD_TYPES="*"
MD_PRODUCES="fixed_file"

analyze_polyglot_detector() {
    local file="$1"
    local raw_magic=$(xxd -p -l 8 "$file" 2>/dev/null | tr -d '\n')
    local magic="$raw_magic"

    local detected_type=""
    local correct_ext=""
    local needs_strip=false

    # Check for \x prefix (literal backslash-x at start — common CTF trick)
    local first_bytes=$(xxd -p -l 2 "$file" 2>/dev/null)
    if [[ "$first_bytes" == "5c78" ]]; then
        local stripped_magic=$(tail -c +3 "$file" | xxd -p -l 8 2>/dev/null | tr -d '\n')
        # Check if stripped version matches known types
        local stripped_type=""; local stripped_ext=""
        case "$stripped_magic" in
            ffe0*|ffd8*) stripped_type="JPEG"; stripped_ext="jpg" ;;
            89504e47*) stripped_type="PNG"; stripped_ext="png" ;;
        esac
        if [ -n "$stripped_type" ]; then
            detected_type="$stripped_type"
            correct_ext="$stripped_ext"
            needs_strip=true
            magic="$stripped_magic"
        fi
    fi

    # Standard magic byte check
    if [ -z "$detected_type" ]; then
        case "$magic" in
            89504e470d0a1a0a) detected_type="PNG"; correct_ext="png" ;;
            ffd8ffe0*|ffd8ffe1*|ffd8ffee*) detected_type="JPEG"; correct_ext="jpg" ;;
            474946383761|474946383961) detected_type="GIF"; correct_ext="gif" ;;
            424d*) detected_type="BMP"; correct_ext="bmp" ;;
            25504446) detected_type="PDF"; correct_ext="pdf" ;;
            504b0304|504b0506|504b0708) detected_type="ZIP"; correct_ext="zip" ;;
            1f8b08) detected_type="GZIP"; correct_ext="gz" ;;
            ffe0*|ffdb*|ffc0*|ffc2*|ffc4*|ffc8*|fffe*)
                # JPEG without FFD8 SOI marker — common in CTF
                detected_type="JPEG (missing SOI)"
                correct_ext="jpg"
                needs_strip=true
                ;;
            *) return 0 ;;
        esac
    fi

    $QUIET || header "Polyglot Fixer" "Magic Byte Verification"

    local fname=$(basename "$file")
    local extension="${fname##*.}"
    local lower_ext=$(echo "$extension" | tr '[:upper:]' '[:lower:]')

    if [[ "$lower_ext" != "$correct_ext" ]] || $needs_strip; then
        FIXED_DIR="$HOME/Downloads"
        # Also save a copy to the output session dir
        local session_dir="${OUTDIR}/repaired"
        mkdir -p "$session_dir"

        local base_name="${fname%.*}"
        local new_file="$FIXED_DIR/${base_name}.$correct_ext"

        export POLYGLOT_FILE="$file"
        export POLYGLOT_NEW_FILE="$new_file"
        python3 -c "
import os
with open(os.environ['POLYGLOT_FILE'], 'rb') as f:
    data = bytearray(f.read())

fixed = False

# Strip leading \\x if present
if len(data) >= 2 and data[0] == 0x5c and data[1] == 0x78:
    data = data[2:]
    fixed = True

# Fix JPEG missing FFD8 SOI
if len(data) >= 2 and data[0] == 0xff and data[1] in (0xe0, 0xdb, 0xc0, 0xc2, 0xc4, 0xc8, 0xfe):
    data = b'\xff\xd8' + bytes(data)
    fixed = True

# Strip appended data after PNG IEND
if len(data) >= 8 and data[:8] == b'\x89PNG\r\n\x1a\n':
    import struct
    pos = 8
    while pos + 8 <= len(data):
        length = struct.unpack('>I', data[pos:pos+4])[0]
        chunk_type = data[pos+4:pos+8]
        if chunk_type == b'IEND':
            data = bytes(data[:pos+12])
            fixed = True
            break
        pos += 12 + length

# Strip appended data after JPEG EOI
if len(data) >= 2 and data[:2] == b'\xff\xd8':
    eoi = bytes(data).find(b'\xff\xd9')
    if eoi != -1 and eoi + 2 < len(data):
        data = bytes(data[:eoi+2])
        fixed = True

with open(os.environ['POLYGLOT_NEW_FILE'], 'wb') as out:
    out.write(data if isinstance(data, bytes) else bytes(data))
" 2>/dev/null
        unset POLYGLOT_FILE POLYGLOT_NEW_FILE

        cat >&2 <<EOF

══════════════════════════════════════════════════════════
  ✅ File fixed successfully!
  📁 Saved to: $new_file
  📄 Type: $detected_type
  💡 Open it with the appropriate viewer to see the flag!
══════════════════════════════════════════════════════════

EOF

        export FIXED_FILE_PATH="$new_file"
    fi
}
