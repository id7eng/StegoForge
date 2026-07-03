
```
   _________ __        ________                   
  /   _____/  |_____  \_____  \___  ___  ___  ___ 
  \_____  \|  |  \__  \ /  ____/  / /  /  /  \  \
  /        \   |  / __ \ >     <  / /  /  /   >   \
 /_______  /___| (____  /___/\  \/ /  /  /___/  /\  \
         \/     \/     \/      \_/           \/  \_/
```

# StegoForge — v1.3.3

**The All-in-One CTF Steganography & Forensics Arsenal**

44 modules · 25+ formats · Smart workflow · Auto-detect · Auto-repair · No AI

```
stegoforge image.png          →  flag / partial flag
stegoforge -v image.jpg       →  full forensic report
stegoforge -r ~/CTF/          →  recursive directory scan
stegoforge --json file.png    →  structured JSON output
stegoforge --doctor           →  check installed tools
```

---

## Quick Start

```bash
git clone https://github.com/id7eng/StegoForge.git
cd StegoForge && chmod +x install.sh && ./install.sh
stegoforge suspicious.png
```

*No root?* Every module auto-skips if tools are missing. Run `stegoforge --doctor` to see what's available.

---

## Features

| Category | Feature | What it does |
|----------|---------|-------------|
| **🔍 Smart Analysis** | Polyglot Detection | Catches magic-byte vs extension mismatch, strips appended data, saves clean copy to `~/Downloads/` |
| | Auto-Repair | Fixes broken PNG IHDR CRCs, JPEG SOI markers, missing magic bytes |
| | Re-Analysis Loop | After repair, engine re-scans the fixed file |
| | Partial Flag Detection | Catches flag fragments and tails when full patterns don't match |
| | OCR Auto-Scale | Auto-upscales tiny images before Tesseract OCR |
| **⚙️ Workflow Engine** | Event System | Modules `emit()` findings; others subscribed via `MD_TRIGGERS` react |
| | Priority Dispatch | All 44 modules run in strict `MD_PRIORITY` order |
| | Smart Wordlist | Parses metadata + strings + filename to build targeted passwords |
| | Gzip Auto-Decompress | Auto-detects and decompresses gzip'd files |
| **📊 Output** | Default | Clean flag / partial flag |
| | `-v` | Full per-module verbose report |
| | `--summary` | `file → flag` one-liner (ideal for `-r`) |
| | `--json` | `{"file":"...", "flags":["..."], "status":"found\|partial\|empty"}` |
| **🛡 Security** | Read-Only Mode | `--readonly` copies to `/tmp`; original never modified |
| | Python Injection Protection | All paths via env vars, not string interpolation |
| | No Pipe Subshells | Every `while read` uses `done < <(cmd)` — no data loss |
| | Graceful Degradation | Missing deps = auto-skip, no crashes |
| | Null-Byte Safety | `LC_ALL=C` + `tr -d '\0'` throughout |

---

## 44 Modules

### Universal (every file type — 16)

| Pri | Module | Description |
|-----|--------|-------------|
| 1 | Repair | Fix corrupted magic bytes, PNG IHDR CRC, JPEG headers |
| 2 | Polyglot Fixer | Detect magic-byte mismatch → fix, strip, save to `~/Downloads/` |
| 5 | Smart Wordlist | Context-aware password generator from file data |
| 7 | Binary Digits | Decode ASCII `0`/`1` text to binary |
| 8 | Base64 Full | Decode base64 + hex-encoded base64 |
| 10 | Strings | Keyword grep · auto base64/hex · flag + partial flag matching |
| 11 | ROT Brute | Brute-force ROT1–25 + Atbash cipher |
| 16 | EXIF Thumbnail | Extract & analyze embedded EXIF thumbnails |
| 22 | OCR | Tesseract OCR with auto-upscale |
| 28 | Append Data | Detect data appended after IEND / FFD9 / EOF |
| 50 | PCAP Analysis | HTTP objects · DNS · TCP streams · IPv6 · BPF filters |
| 52 | Disk Forensics | Loop-mount FAT/NTFS/ext4 images |
| 60 | Binwalk | Detect & extract embedded files |
| 70 | Foremost | File carving from raw images |
| 80 | XOR Brute | Single-byte XOR key recovery (0x00–0xFF) |
| 90 | ADS Scan | NTFS Alternate Data Stream enumeration |

### Image Analysis (18)

| Pri | Module | Formats | Description |
|-----|--------|---------|-------------|
| 12 | Video | mp4, avi, mov, mkv, webm | Frame extraction, QR, accumulation, differencing |
| 15 | StegDetect | jpg, jpeg | Identify embedding tool (jphide, outguess, jsteg, F5) |
| 20 | Metadata | jpg, png, bmp, gif, tiff, webp | Exif/ID3/XMP + acrostic analysis |
| 25 | PNG CRC | png | CRC check + brute-force correct dimensions |
| 30 | Zsteg | png, bmp | LSB steganography detection |
| 35 | QR | jpg, jpeg, png, bmp, gif | QR / barcode scanning |
| 36 | Stepic | png, bmp | LSB decode via stepic library |
| 36 | PDF Images | pdf | Extract embedded raster images |
| 37 | GIF Palette | gif | Per-frame palette analysis |
| 38 | PDF Analysis | pdf | Decompression, comments, post-%%EOF data |
| 39 | StegSeek | jpg, jpeg, bmp, wav | 100× faster steghide cracking |
| 40 | Steghide | jpg, jpeg, bmp, wav | Data extraction + brute-force |
| 42 | OutGuess | jpg, jpeg | OutGuess data extraction |
| 43 | JPHide | jpg, jpeg | JPHide data extraction |
| 44 | F5 | jpg, jpeg | F5 data extraction |
| 45 | Bit Plane | png, bmp | Extract bit planes 0–7 as PNGs |
| 46 | JPEG DQT | jpg, jpeg | LSB from unused quantization tables |
| 47 | Binary Border | jpg, png, bmp, gif | Read border pixels clockwise as binary |
| 49 | FFT Domain | jpg, png, bmp, gif | Frequency domain analysis |

### Audio Analysis (5)

| Pri | Module | Formats | Description |
|-----|--------|---------|-------------|
| 48 | MP3Stego | mp3 | Extract MP3Stego hidden data |
| 50 | Spectrogram | wav, au, mp3 | Generate spectrogram image |
| 51 | Audio Reverse | wav, mp3, au | Reverse audio + flag search |
| 52 | SSTV | wav | Decode slow-scan television images |
| 53 | DTMF | wav | Decode telephone tones (multimon-ng) |

### Documents & Text (3)

| Pri | Module | Formats | Description |
|-----|--------|---------|-------------|
| 32 | Snow | txt, html, css, js | Whitespace steganography decode |
| 33 | Zero Width | txt, html, css, js | Detect zero-width Unicode characters |
| 34 | OleVBA | doc, docx, xls, xlsx, ppt, pptx | Office macro analysis |

### Archives (1)

| Pri | Module | Formats | Description |
|-----|--------|---------|-------------|
| 55 | ZIP Brute | zip | Crack passwords (fcrackzip + unzip fallback) |

---

## Architecture

```
                    ┌──────────────┐
                    │  stegoforge  │
                    │  (entry)     │
                    └──────┬───────┘
                           │
                    ┌──────▼───────┐
                    │  engine.sh   │
                    │  (workflow)  │
                    └──────┬───────┘
                           │
          ┌────────────────┼────────────────┐
          │                │                │
   ┌──────▼──────┐   ┌─────▼──────┐  ┌──────▼──────┐
   │   Repair /  │   │  Priority  │  │   Feature   │
   │   Polyglot  │   │  Scheduler │  │   Modules   │
   └─────────────┘   └────────────┘  └─────────────┘
```

**Pipeline:**
1. **Repair** (pri 1-2): Fix headers, detect polyglot, save fixed copy
2. **Prep** (pri 5): Smart wordlist, gzip decompress
3. **Analyze** (pri 7-90): 44 modules run in priority order, emit events
4. **Report**: Collect flags, output as default/json/summary

---

## Output

```
~/Downloads/
  <file>.png / .jpg / .gif      ← Polyglot Fixer clean copy

output/sessions/<pid>/
  carved/                        ← Extracted files, frames, wordlists
  bitplanes/                     ← Bit plane images (0–7)
  spectrograms/                  ← Spectrogram images
  repaired/                      ← Repaired files
  reports/                       ← (future)
```

---

## Module API

Drop a file in `modules/`:

```bash
MD_NAME="MyModule"
MD_DESC="What it does"
MD_TYPES="jpg png"
MD_PRIORITY=42
MD_PRODUCES="my_data flag"
MD_TRIGGERS="repair polyglot_fixed"

analyze_mymodule() {
    local f="$1" wl="$2"
    emit "my_data" "Found: $data"
}
```

**Variables:** `$f`, `$wl`, `$OUTDIR`, `$FLAG_PATTERNS`, `$SMART_WL`, `$VERBOSE`

---

## Tests

```bash
./tests/run_tests.sh
```

| Status | Count |
|--------|-------|
| ✅ Pass | 22 |
| ❌ Fail | 0 |
| ⏭️ Skip | 3 (QR/pyzbar, PDF/reportlab, Disk/mount) |
| **Total** | **28** |

---

## Coding Standards

- No `eval`
- No inline `python3 -c` with string interpolation — use env vars
- No `cmd | while read` — use `done < <(cmd)`
- Flag output via `emit "flag" "..."`, never `echo`
- Modules gracefully skip missing deps, never crash

---

## License

MIT — Use it, modify it, ship it.

---

<p align="center">
  <a href="https://github.com/id7eng/StegoForge">GitHub</a> · <a href="https://github.com/id7eng/StegoForge/issues">Issues</a> · <a href="https://github.com/id7eng/StegoForge/releases">Releases</a><br>
  <sub>Built for the CTF community · No AI · No Payments · Just tools</sub>
</p>
