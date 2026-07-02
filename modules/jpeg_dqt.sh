MD_NAME="JPEG DQT"
MD_DESC="Extract LSB from unused JPEG quantization tables"
MD_TYPES="jpg jpeg"
MD_DEPS="python3"
MD_PRIORITY=46
MD_PRODUCES="dqt_data flag"

analyze_jpeg_dqt() {
    local f="$1"
    header "JPEG DQT" "Quantization Table LSB"

    python3 -c "
import struct

with open('$f', 'rb') as f:
    data = f.read()

# Find all DQT markers (0xFFDB)
pos = 0
tables = {}
while True:
    pos = data.find(b'\xff\xdb', pos)
    if pos == -1:
        break
    length = struct.unpack('>H', data[pos+2:pos+4])[0]
    table_data = data[pos+4:pos+4+length-2]
    table_id = table_data[0] & 0x0F  # Lower nibble = table ID
    coeffs = list(table_data[1:])
    tables[table_id] = coeffs
    pos += 4 + length - 2

if not tables:
    exit(0)

# Extract LSB from each table
for tid, coeffs in tables.items():
    bits = ''.join(str(c & 1) for c in coeffs)
    chars = ''
    for i in range(0, len(bits) - len(bits) % 8, 8):
        b = bits[i:i+8]
        if 32 <= int(b, 2) <= 126:
            chars += chr(int(b, 2))
    if len(chars) > 3:
        print(f'DQT[{tid}]: {chars}')
" 2>/dev/null | while read line; do
        emit "dqt_data" "JPEG DQT: $line"
    done
}
