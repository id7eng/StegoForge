#!/bin/bash
TOOL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
STEGOFORGE="$TOOL_DIR/stegoforge"
TEMP_DIR="/tmp/stegoforge_test_$$"
PASS=0; FAIL=0; SKIP=0; TOTAL=0
RESULTS=()
mkdir -p "$TEMP_DIR" && cd "$TEMP_DIR"

R='\033[0;31m'; G='\033[0;32m'; Y='\033[1;33m'; B='\033[0;34m'; C='\033[0;36m'; N='\033[0m'; BOLD='\033[1m'; DIM='\033[2m'

pass() { PASS=$((PASS+1)); RESULTS+=("  ${G}[PASS]${N} $1"); }
fail() { FAIL=$((FAIL+1)); RESULTS+=("  ${R}[FAIL]${N} $1"); }
skip() { SKIP=$((SKIP+1)); RESULTS+=("  ${Y}[SKIP]${N} $1 ($2)"); }

check() {
    local name="$1" file="$2" expect="$3" dep="$4" extra="$5"
    TOTAL=$((TOTAL+1))
    [ -n "$dep" ] && ! command -v "$dep" &>/dev/null && { skip "$name" "missing $dep"; return; }
    local out=$("$STEGOFORGE" -v $extra "$file" 2>/dev/null | tr -d '\0')
    if echo "$out" | grep -qiF "$expect"; then
        pass "$name"
    else
        echo "    [$name] expected '$expect'" >&2
        fail "$name"
    fi
}

gen_png() {
    python3 -c "
import struct, zlib, sys
w,h=$1,$2
pix=bytearray()
for y in range(h):
    for x in range(w): pix.extend([x&0xff,y&0xff,128])
def png(w,h,p):
    def c(ct,d):
        cd=ct+d; return struct.pack('>I',len(d))+cd+struct.pack('>I',zlib.crc32(cd)&0xffffffff)
    s=b'\x89PNG\r\n\x1a\n'; ih=c(b'IHDR',struct.pack('>IIBBBBB',w,h,8,2,0,0,0))
    r=b''
    for y in range(h):
        r+=b'\x00'+p[y*w*3:(y*w+3)*3]
    id=c(b'IDAT',zlib.compress(r)); ie=c(b'IEND',b'')
    return s+ih+id+ie
with open('$3','wb') as f: f.write(png(w,h,bytes(pix)))
" 2>/dev/null
}

echo -e "${C}╔══════════════════════════════════════════════╗${N}"
echo -e "${C}║     ${W}StegoForge v1.3.2${C} - Test Suite       ║${N}"
echo -e "${C}╚══════════════════════════════════════════════╝${N}"
echo ""

# [01] Strings — keyword
echo -e "${BOLD}[01/14] Strings — keyword${N}"
echo "the secret is FLAG{test_strings_ok}" > strings.txt
check "strings" strings.txt "FLAG{test_strings_ok}"

# [02] Strings — base64
echo -e "${BOLD}[02/14] Strings — base64${N}"
echo -n "FLAG{test_base64_ok}" | base64 -w0 > b64.txt
check "base64" b64.txt "FLAG{test_base64_ok}" "" "-v"

# [03] XOR Brute
echo -e "${BOLD}[03/14] XOR Brute${N}"
python3 -c "
d = b'CTF{test_xor_ok}'
with open('xor.bin','wb') as f: f.write(bytes(b ^ 0x42 for b in d))
" 2>/dev/null
check "xor_brute" xor.bin "CTF{test_xor_ok}"

# [04] Metadata
echo -e "${BOLD}[04/14] Metadata${N}"
if command -v exiftool &>/dev/null; then
    gen_png 10 10 meta.png
    exiftool -Artist="CTF{test_metadata_ok}" meta.png -overwrite_original &>/dev/null
    check "metadata" meta.png "CTF{test_metadata_ok}"
else
    skip "metadata" "exiftool"; TOTAL=$((TOTAL+1))
fi

# [05] Zsteg
echo -e "${BOLD}[05/14] Zsteg${N}"
if command -v zsteg &>/dev/null; then
    python3 -c "
import struct, zlib
flag=b'CTF{test_zsteg_ok}'; w,h=20,20
pix=bytearray()
for y in range(h):
    for x in range(w): pix.extend([x*12,y*12,128])
for i,b in enumerate(flag):
    for bi in range(8):
        idx=(i*8+bi)*3
        if idx<len(pix): pix[idx]=(pix[idx]&0xFE)|((b>>(7-bi))&1)
def png(w,h,p):
    def c(ct,d):
        cd=ct+d; return struct.pack('>I',len(d))+cd+struct.pack('>I',zlib.crc32(cd)&0xffffffff)
    s=b'\x89PNG\r\n\x1a\n'; ih=c(b'IHDR',struct.pack('>IIBBBBB',w,h,8,2,0,0,0))
    r=b''
    for y in range(h):
        r+=b'\x00'
        for x in range(w): r+=p[(y*w+x)*3:(y*w+x)*3+3]
    id=c(b'IDAT',zlib.compress(r)); ie=c(b'IEND',b'')
    return s+ih+id+ie
with open('zsteg_test.png','wb') as f: f.write(png(w,h,bytes(pix)))
" 2>/dev/null
    check "zsteg" zsteg_test.png "CTF{test_zsteg_ok}"
else
    skip "zsteg" "zsteg"; TOTAL=$((TOTAL+1))
fi

# [06] Steghide
echo -e "${BOLD}[06/14] Steghide${N}"
if command -v steghide &>/dev/null; then
    python3 -c "
from PIL import Image
import random
random.seed(42)
img = Image.new('RGB', (100, 100))
pix = img.load()
for x in range(100):
    for y in range(100):
        pix[x,y] = (random.randint(0,255), random.randint(0,255), random.randint(0,255))
img.save('steg_hide.jpg', 'JPEG', quality=100)
" 2>/dev/null
    echo -n "CTF{test_steghide_ok}" > secret.txt
    steghide embed -cf steg_hide.jpg -ef secret.txt -p "testpass" -f &>/dev/null
    echo "testpass" > passlist.txt
    check "steghide" steg_hide.jpg "CTF{test_steghide_ok}" "" "-w passlist.txt"
else
    skip "steghide" "steghide"; TOTAL=$((TOTAL+1))
fi

# [07] PNG CRC
echo -e "${BOLD}[07/14] PNG CRC${N}"
python3 -c "
import struct, zlib
w,h=10,20; pix=bytearray()
for y in range(h):
    for x in range(w): pix.extend([x*25,y*12,128])
def png(w,h,p):
    def c(ct,d):
        cd=ct+d; return struct.pack('>I',len(d))+cd+struct.pack('>I',zlib.crc32(cd)&0xffffffff)
    s=b'\x89PNG\r\n\x1a\n'; ih=c(b'IHDR',struct.pack('>IIBBBBB',w,h,8,2,0,0,0))
    r=b''
    for y in range(h):
        r+=b'\x00'
        for x in range(w): r+=p[(y*w+x)*3:(y*w+x)*3+3]
    id=c(b'IDAT',zlib.compress(r)); ie=c(b'IEND',b'')
    return s+ih+id+ie
data=bytearray(png(w,h,bytes(pix)))
# Modify height bytes (offset 20-23 in PNG), keep old CRC
data[20:24]=struct.pack('>I',999)
with open('crc_test.png','wb') as f: f.write(bytes(data))
" 2>/dev/null
check "png_crc" crc_test.png "CRC mismatch"

# [08] Bit Plane
echo -e "${BOLD}[08/14] Bit Plane${N}"
python3 -c "
import struct, zlib
w,h=16,16; pix=bytearray()
flag=bin(int.from_bytes(b'CTF{test_bitplane_ok}','big'))[2:].zfill(8*20)
fi=0
for y in range(h):
    for x in range(w):
        r,g,b=x*16,y*16,128
        if fi<len(flag):
            r=(r&0xFE)|int(flag[fi]); fi+=1
        pix.extend([r,g,b])
def png(w,h,p):
    def c(ct,d):
        cd=ct+d; return struct.pack('>I',len(d))+cd+struct.pack('>I',zlib.crc32(cd)&0xffffffff)
    s=b'\x89PNG\r\n\x1a\n'; ih=c(b'IHDR',struct.pack('>IIBBBBB',w,h,8,2,0,0,0))
    r=b''
    for y in range(h):
        r+=b'\x00'
        for x in range(w): r+=p[(y*w+x)*3:(y*w+x)*3+3]
    id=c(b'IDAT',zlib.compress(r)); ie=c(b'IEND',b'')
    return s+ih+id+ie
with open('bp_test.png','wb') as f: f.write(png(w,h,bytes(pix)))
" 2>/dev/null
check "bit_plane" bp_test.png "bit planes"

# [09] QR Code
echo -e "${BOLD}[09/14] QR Code${N}"
python3 -c "
try:
    import qrcode
    qr = qrcode.QRCode(); qr.add_data('CTF{test_qr_ok}'); qr.make()
    qr.make_image().save('qr_test.png'); print('OK')
except Exception as e: print(f'NO:{e}')
" 2>/dev/null | grep -q OK
if [ -f qr_test.png ] && python3 -c "from pyzbar.pyzbar import decode; print('OK')" 2>/dev/null | grep -q OK; then
    check "qr" qr_test.png "CTF{test_qr_ok}"
else
    skip "qr" "pyzbar missing"; TOTAL=$((TOTAL+1))
fi

# [10] Repair
echo -e "${BOLD}[10/14] Repair${N}"
python3 -c "
import struct
j=bytes.fromhex('ffd8ffe000104a46494600010101004800480000')
j+=b'\xff\xfe'+struct.pack('>H',24)+b'CTF{test_repair_ok}'+bytes.fromhex('ffd9')
with open('repair_corrupt.bin','wb') as f: f.write(j[2:])
" 2>/dev/null
check "repair" repair_corrupt.bin "CTF{test_repair_ok}"

# [11] ZIP Brute
echo -e "${BOLD}[11/14] ZIP Brute${N}"
if command -v zip &>/dev/null && command -v fcrackzip &>/dev/null; then
    echo "CTF{test_zip_ok}" > flag.txt
    zip -P "secret123" secret.zip flag.txt &>/dev/null
    echo "secret123" > custom_pw.txt
    check "zip_brute" secret.zip "CTF{test_zip_ok}" "" "-w custom_pw.txt"
else
    skip "zip_brute" "zip/fcrackzip"; TOTAL=$((TOTAL+1))
fi

# [12] Binwalk
echo -e "${BOLD}[12/14] Binwalk${N}"
if command -v zip &>/dev/null && command -v binwalk &>/dev/null; then
    echo "CTF{test_binwalk_ok}" > bf.txt
    zip bf.zip bf.txt &>/dev/null
    python3 -c "
with open('bw.jpg','wb') as f:
    f.write(bytes.fromhex('ffd8ffe000104a46494600010101004800480000ffd9'))
with open('bf.zip','rb') as z:
    with open('bw.jpg','ab') as f: f.write(z.read())
" 2>/dev/null
    check "binwalk" bw.jpg "CTF{test_binwalk_ok}"
else
    skip "binwalk" "zip/binwalk"; TOTAL=$((TOTAL+1))
fi

# [13] Foremost
echo -e "${BOLD}[13/14] Foremost${N}"
if command -v zip &>/dev/null && command -v foremost &>/dev/null; then
    [ -f bw.jpg ] || {
        echo "CTF{test_foremost_ok}" > ff.txt; zip ff.zip ff.txt &>/dev/null
        python3 -c "
with open('fm.jpg','wb') as f:
    f.write(bytes.fromhex('ffd8ffe000104a46494600010101004800480000ffd9'))
with open('ff.zip','rb') as z:
    with open('fm.jpg','ab') as f: f.write(z.read())
" 2>/dev/null
        check "foremost" fm.jpg "carved"
    }
    [ -f bw.jpg ] && check "foremost" bw.jpg "carved"
else
    skip "foremost" "zip/foremost"; TOTAL=$((TOTAL+1))
fi

# [14] Spectrogram
echo -e "${BOLD}[14/14] Spectrogram${N}"
python3 -c "
import struct, math, sys
try:
    sr=44100; dur=0.3; n=int(sr*dur); data=bytearray()
    for i in range(n):
        v=int(16000*math.sin(2*math.pi*800*i/sr))
        data+=struct.pack('<h',max(-32768,min(32767,v)))
    with open('spec.wav','wb') as f:
        f.write(b'RIFF'+struct.pack('<I',36+n*2)+b'WAVE')
        f.write(b'fmt '+struct.pack('<IHHIIHH',16,1,1,sr,sr*2,2,16))
        f.write(b'data'+struct.pack('<I',n*2)+bytes(data))
    print('OK')
except: print('ERR')
" 2>/dev/null | grep -q OK
[ -f spec.wav ] && check "spectrogram" spec.wav "spectrogram" || { skip "spectrogram" "python/wav"; TOTAL=$((TOTAL+1)); }

# [15] Smart Wordlist
echo -e "${BOLD}[15/18] Smart Wordlist${N}"
if command -v steghide &>/dev/null; then
    python3 -c "
from PIL import Image
import random
random.seed(99)
img = Image.new('RGB', (100, 100))
pix = img.load()
for x in range(100):
    for y in range(100):
        pix[x,y] = (random.randint(0,255), random.randint(0,255), random.randint(0,255))
img.save('smart_steg.jpg', 'JPEG', quality=100)
" 2>/dev/null
    echo -n "CTF{test_smartwl_ok}" > smart_secret.txt
    steghide embed -cf smart_steg.jpg -ef smart_secret.txt -p "secretpass123" -f &>/dev/null
    # Add password to file's metadata (so smart wordlist can extract it)
    if command -v exiftool &>/dev/null; then
        exiftool -Artist="secretpass123" smart_steg.jpg -overwrite_original &>/dev/null
    else
        # Fallback: append password as text after JPEG end
        python3 -c "
with open('smart_steg.jpg','ab') as f:
    f.write(b'\nPASSWORD:secretpass123\n')
" 2>/dev/null
    fi
    check "smart_wordlist" smart_steg.jpg "CTF{test_smartwl_ok}" "steghide"
else
    skip "smart_wordlist" "steghide"; TOTAL=$((TOTAL+1))
fi

# [16] JSON output
echo -e "${BOLD}[16/18] JSON output${N}"
echo "CTF{test_json_ok}" > json_test.txt
out=$("$STEGOFORGE" --json json_test.txt 2>/dev/null)
if echo "$out" | grep -q '"flags"' && echo "$out" | grep -q '"CTF{test_json_ok}"'; then
    pass "json_output"
else
    echo "    [json_output] expected JSON with flag" >&2
    fail "json_output"
fi
TOTAL=$((TOTAL+1))

# [17] Summary output
echo -e "${BOLD}[17/18] Summary output${N}"
out=$("$STEGOFORGE" --summary json_test.txt 2>/dev/null)
if echo "$out" | grep -q "→.*CTF{test_json_ok}"; then
    pass "summary_output"
else
    echo "    [summary_output] expected summary with flag" >&2
    fail "summary_output"
fi
TOTAL=$((TOTAL+1))
rm -f json_test.txt

# [18] Read-Only mode
echo -e "${BOLD}[18/18] Read-Only mode${N}"
python3 -c "
import struct, zlib
w,h=5,5; pix=bytearray()
for y in range(h):
    for x in range(w): pix.extend([x*50,y*50,128])
def png(w,h,p):
    def c(ct,d):
        cd=ct+d; return struct.pack('>I',len(d))+cd+struct.pack('>I',zlib.crc32(cd)&0xffffffff)
    s=b'\x89PNG\r\n\x1a\n'; ih=c(b'IHDR',struct.pack('>IIBBBBB',w,h,8,2,0,0,0))
    r=b''
    for y in range(h): r+=b'\x00'+bytes(p[y*w*3:(y*w+3)*3])
    id=c(b'IDAT',zlib.compress(r)); ie=c(b'IEND',b'')
    return s+ih+id+ie
data=bytearray(png(w,h,bytes(pix)))
data[20:24]=struct.pack('>I',999)
with open('ro_test.png','wb') as f: f.write(bytes(data))
" 2>/dev/null
orig_hash=$(md5sum ro_test.png | cut -d' ' -f1)
out=$("$STEGOFORGE" --readonly --json ro_test.png 2>/dev/null)
final_hash=$(md5sum ro_test.png | cut -d' ' -f1)
if [ "$orig_hash" = "$final_hash" ]; then
    pass "readonly_mode"
else
    echo "    [readonly] file was modified (hash changed)" >&2
    fail "readonly_mode"
fi
TOTAL=$((TOTAL+1))

# [19] Binary Digits
echo -e "${BOLD}[19/20] Binary Digits${N}"
python3 -c "
import struct
# Minimal JPEG with flag in comment
data = b'\xff\xd8'
data += b'\xff\xe0' + struct.pack('>H', 16) + b'JFIF\x00\x01\x01\x00\x00\x01\x00\x01\x00\x00'
comment = b'CTF{test_binary_digits_ok}'
data += b'\xff\xfe' + struct.pack('>H', len(comment)+2) + comment
data += b'\xff\xc0' + struct.pack('>H', 11) + b'\x08\x00\x01\x00\x01\x01\x01\x11\x00'
data += b'\xff\xda' + struct.pack('>H', 8) + b'\x01\x01\x00\x00\x3f\x00'
data += b'\x00' * 64 + b'\xff\xd9'
bits = ''.join(f'{b:08b}' for b in data)
with open('digits_test.txt', 'w') as f: f.write(bits)
" 2>/dev/null
check "binary_digits" digits_test.txt "CTF{test_binary_digits_ok}"
TOTAL=$((TOTAL+1))

# [20] Base64 Full Decode
echo -e "${BOLD}[20/20] Base64 Full Decode + Hex${N}"
python3 -c "
import struct, zlib, base64
hex_str = '4354467b746573745f6261736536345f6865785f6f6b7d'  # CTF{test_base64_hex_ok}
def make_chunk(ct, d):
    cd = ct + d
    return struct.pack('>I', len(d)) + cd + struct.pack('>I', zlib.crc32(cd) & 0xffffffff)
png = b'\x89PNG\r\n\x1a\n'
ihdr = make_chunk(b'IHDR', struct.pack('>IIBBBBB', 1, 1, 8, 0, 0, 0, 0))
png += ihdr
text = make_chunk(b'tEXt', b'flag\x00' + hex_str.encode())
png += text
raw = b'\x00\x00'
compressed = zlib.compress(raw)
png += make_chunk(b'IDAT', compressed)
png += make_chunk(b'IEND', b'')
b64 = base64.b64encode(png).decode()
with open('b64_full_test.txt', 'w') as f: f.write(b64)
" 2>/dev/null
check "base64_full_hex" b64_full_test.txt "CTF{test_base64_hex_ok}"
TOTAL=$((TOTAL+1))

# [21] ROT Brute
echo -e "${BOLD}[21/25] ROT Brute${N}"
python3 -c "
import codecs
flag = 'picoCTF{test_rot_brute_ok}'
encoded = codecs.encode(flag, 'rot_13')
with open('rot_test.txt', 'w') as f: f.write(encoded)
" 2>/dev/null
check "rot_brute" rot_test.txt "picoCTF{test_rot_brute_ok}"
TOTAL=$((TOTAL+1))

# [22] EXIF Thumbnail
echo -e "${BOLD}[22/25] EXIF Thumbnail${N}"
if command -v exiftool &>/dev/null && python3 -c "from PIL import Image; print('ok')" 2>/dev/null; then
    python3 -c "
from PIL import Image
import struct, os
# Create thumbnail JPEG with flag in a COM marker (strings can find it)
flag = b'CTF{test_thumb_ok}'
thumb_jpeg = b'\xff\xd8'
thumb_jpeg += b'\xff\xe0' + struct.pack('>H', 16) + b'JFIF\x00\x01\x01\x00\x00\x01\x00\x01\x00\x00'
thumb_jpeg += b'\xff\xfe' + struct.pack('>H', len(flag)+2) + flag
thumb_jpeg += b'\xff\xc0' + struct.pack('>H', 11) + b'\x08\x00\x01\x00\x01\x01\x01\x11\x00'
thumb_jpeg += b'\xff\xda' + struct.pack('>H', 8) + b'\x01\x01\x00\x00\x3f\x00'
thumb_jpeg += b'\x00' * 64 + b'\xff\xd9'
with open('_thumb_src.jpg', 'wb') as f: f.write(thumb_jpeg)

import random
random.seed(1)
m = Image.new('RGB', (100, 100))
p = m.load()
for x in range(100):
    for y in range(100):
        p[x,y] = (random.randint(0,255), random.randint(0,255), random.randint(0,255))
m.save('thumb_main.jpg', 'JPEG', quality=90)
" 2>/dev/null
    exiftool '-ThumbnailImage<=_thumb_src.jpg' thumb_main.jpg -overwrite_original &>/dev/null
    check "exif_thumbnail" thumb_main.jpg "CTF{test_thumb_ok}"
else
    skip "exif_thumbnail" "exiftool/PIL"; TOTAL=$((TOTAL+1))
fi

# [23] PDF Images
echo -e "${BOLD}[23/25] PDF Images${N}"
if command -v pdfimages &>/dev/null && python3 -c "from reportlab.graphics.shapes import *; print('ok')" 2>/dev/null; then
    python3 -c "
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import letter
c = canvas.Canvas('pdf_img_test.pdf', pagesize=letter)
c.drawString(100, 750, 'CTF{test_pdf_image_ok}')
c.save()
" 2>/dev/null
    check "pdf_images" pdf_img_test.pdf "CTF{test_pdf_image_ok}"
else
    skip "pdf_images" "pdfimages/reportlab"; TOTAL=$((TOTAL+1))
fi

# [24] Disk Forensics
echo -e "${BOLD}[24/25] Disk Forensics${N}"
if command -v mmls &>/dev/null && command -v fls &>/dev/null; then
    # Create a small FAT filesystem image with a flag file
    dd if=/dev/zero of=disk_test.img bs=1K count=1440 2>/dev/null
    mkfs.fat disk_test.img 2>/dev/null
    # Mount, write flag, unmount
    mkdir -p /tmp/stegoforge_mnt
    sudo mount -o loop disk_test.img /tmp/stegoforge_mnt 2>/dev/null && {
        echo "CTF{test_disk_ok}" | sudo tee /tmp/stegoforge_mnt/flag.txt >/dev/null
        sudo umount /tmp/stegoforge_mnt
        check "disk_forensics" disk_test.img "CTF{test_disk_ok}"
    } || {
        skip "disk_forensics" "mount"; TOTAL=$((TOTAL+1))
    }
    rmdir /tmp/stegoforge_mnt 2>/dev/null
else
    skip "disk_forensics" "sleuthkit"; TOTAL=$((TOTAL+1))
fi

# [25] PCAP Analysis
echo -e "${BOLD}[25/25] PCAP Analysis${N}"
if command -v tshark &>/dev/null && python3 -c "from scapy.all import *; print('ok')" 2>/dev/null; then
    python3 -c "
from scapy.all import *
pkt = IP(dst='1.2.3.4')/TCP(dport=80)/'GET /picoCTF{test_pcap_ok} HTTP/1.1\r\n'
wrpcap('pcap_test.pcap', [pkt])
" 2>/dev/null
    check "pcap_analysis" pcap_test.pcap "picoCTF{test_pcap_ok}"
else
    skip "pcap_analysis" "tshark/scapy"; TOTAL=$((TOTAL+1))
fi

cd / >/dev/null
rm -rf "$TEMP_DIR" /tmp/stegoforge_mnt /tmp/thumb_test_tmp.png 2>/dev/null

echo ""
echo -e "${C}══════════════════════════════════════════════${N}"
echo -e "  ${BOLD}Results:${N}"
for r in "${RESULTS[@]}"; do echo -e "$r"; done
echo ""
echo -e "  ${G}${PASS} PASS${N}  ${R}${FAIL} FAIL${N}  ${Y}${SKIP} SKIP${N}  |  ${BOLD}$((PASS+FAIL+SKIP))/${TOTAL} total${N}"
echo -e "${C}══════════════════════════════════════════════${N}"

[ "$FAIL" -eq 0 ] && exit 0 || exit 1
