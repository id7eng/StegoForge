
```
  ___________        __          _____                 
 /   _____/  | _____/  |_  _____/ ____\____    ____   
 \_____  \|  |/ /\   __\/  _ \   __\\__  \  /    \   
 /        \    <   |  | (  <_> )  |   / __ \|   |  \  
/_______  /__|_ \  |__|  \____/|__|  (____  /___|  /  
        \/     \/                        \/     \/    
```

# StegoForge — v1.3.2

**The All-in-One CTF Steganography & Forensics Arsenal**

> 44 modules · 25+ file formats · Smart workflow engine · Auto-detect · Auto-repair · Zero AI

```bash
stegoforge image.png          # Extract & display flag
stegoforge -v image.jpg       # Full verbose forensic analysis
stegoforge -r ~/CTF/          # Recursive directory scan
```

---

## Installation

```bash
git clone https://github.com/id7eng/StegoForge.git
cd StegoForge
chmod +x install.sh && ./install.sh
```

**No root?** All dependencies gracefully degrade — modules skip automatically if their tools are missing.

---

## Flags & CLI Reference

| Flag | Description |
|------|-------------|
| `stegoforge <file>` | Default — show flag / partial flag only |
| `-v` | Full verbose analysis with all module output |
| `-w <wordlist>` | Supply custom password list for brute-force modules |
| `-r <dir>` | Scan directory recursively (summary output by default) |
| `--json` | Structured JSON output `{"file":"...", "flags":[...], "status":"..."}` |
| `--summary` | One-liner `file → flag` per file |
| `--readonly` | Operate on a copy in `/tmp` — original never touched |
| `--list` | Enumerate all 44 registered modules |
| `--doctor` | Comprehensive dependency health check |
| `--version` | Display version & exit |

---

## Architecture

```
                     ┌─────────────────┐
                     │   stegoforge    │
                     │   (entry point) │
                     └────────┬────────┘
                              │
                     ┌────────▼────────┐
                     │   engine.sh     │
                     │  (workflow)     │
                     └────────┬────────┘
                              │
              ┌───────────────┼───────────────┐
              │               │               │
     ┌────────▼───┐  ┌───────▼──────┐  ┌─────▼─────┐
     │  Repair /  │  │   Priority   │  │  Feature  │
     │  Polyglot  │  │  Scheduler   │  │  Modules  │
     │  Fixer     │  │              │  │  (44)     │
     └────────────┘  └──────────────┘  └───────────┘
```

### How the Workflow Engine Works

1. **Repair Phase** — `MD_PRIORITY=1-2`: Fix corrupted headers, detect polyglot files
2. **Preparation** — `MD_PRIORITY=5`: Smart Wordlist generates context-aware passwords
3. **Analysis** — `MD_PRIORITY=7-90`: All modules execute in priority order
4. **Re-analysis** — If Repair modifies the file, it loops back for a second pass
5. **Reporting** — Collect all `emit()` events, filter flags, generate output

Modules communicate via **events** (`emit "flag" "..."`) and **triggers** — when one module discovers data, others can process it automatically.

---

## Module Catalogue — 44 Modules

### 🛠 Universal (every file type)

| Pri | Module | Description |
|-----|--------|-------------|
| 1 | **Repair** | Fix corrupted magic bytes, PNG IHDR CRC, JPEG headers |
| 2 | **Polyglot Fixer** | Detect magic-byte mismatch → fix header → strip trailing data → save to `~/Downloads/` |
| 5 | **Smart Wordlist** | Generate context-aware passwords from metadata, strings, filename |
| 7 | **Binary Digits** | Decode ASCII `0`/`1` text into binary data |
| 8 | **Base64 Full** | Decode base64 strings + hex-encoded base64 |
| 10 | **Strings** | Keyword grep · auto base64/hex decode · flag pattern matching · partial flag tails |
| 11 | **ROT Brute** | Brute-force ROT1–25 + Atbash cipher |
| 16 | **EXIF Thumbnail** | Extract & analyze embedded EXIF thumbnails |
| 22 | **OCR** | Tesseract OCR with auto-upscale + fuzzy flag matching |
| 28 | **Append Data** | Detect data appended after IEND / FFD9 / EOF markers |
| 50 | **PCAP Analysis** | Extract HTTP objects, DNS queries, TCP streams, IPv6, BPF filters |
| 52 | **Disk Forensics** | Loop-mount FAT/NTFS/ext4 images, extract artifacts |
| 60 | **Binwalk** | Detect & extract embedded files |
| 70 | **Foremost** | File carving / recovery from raw images |
| 80 | **XOR Brute** | Single-byte XOR key recovery (0x00–0xFF) |
| 90 | **ADS Scan** | NTFS Alternate Data Stream enumeration |

### 🖼 Image Analysis

| Pri | Module | Formats | Description |
|-----|--------|---------|-------------|
| 12 | **Video** | mp4, avi, mov, mkv, webm | Frame extraction, QR detection, frame accumulation, motion differencing |
| 15 | **StegDetect** | jpg, jpeg | Identify embedding tool: jphide, outguess, jsteg, F5 |
| 20 | **Metadata** | jpg, png, bmp, gif, tiff, webp | Exif/ID3/XMP extraction + acrostic line analysis |
| 25 | **PNG CRC** | png | CRC integrity check + brute-force correct dimensions |
| 30 | **Zsteg** | png, bmp | LSB steganography detection & extraction |
| 35 | **QR Code** | jpg, jpeg, png, bmp, gif | QR/barcode scanning via pyzbar |
| 36 | **Stepic** | png, bmp | LSB decode via stepic library |
| 36 | **PDF Images** | pdf | Extract all embedded raster images |
| 37 | **GIF Palette** | gif | Per-frame palette analysis for hidden data |
| 38 | **PDF Analysis** | pdf | Multi-layer decompression, comment extraction, post-%%EOF data |
| 39 | **StegSeek** | jpg, jpeg, bmp, wav | 100× faster steghide password cracking |
| 40 | **Steghide** | jpg, jpeg, bmp, wav | Data extraction + password brute-force |
| 42 | **OutGuess** | jpg, jpeg | Extract data from OutGuess-embedded JPEGs |
| 43 | **JPHide** | jpg, jpeg | Data extraction + brute-force |
| 44 | **F5** | jpg, jpeg | Extract data from F5-embedded JPEGs |
| 45 | **Bit Plane** | png, bmp | Extract bit planes 0–7 as individual PNGs |
| 46 | **JPEG DQT** | jpg, jpeg | LSB extraction from unused quantization tables |
| 47 | **Binary Border** | jpg, png, bmp, gif | Read border pixels clockwise as binary data |
| 49 | **FFT Domain** | jpg, png, bmp, gif | Frequency domain analysis for hidden patterns |

### 🎵 Audio Analysis

| Pri | Module | Formats | Description |
|-----|--------|---------|-------------|
| 48 | **MP3Stego** | mp3 | Extract hidden data from MP3Stego-encoded files |
| 50 | **Spectrogram** | wav, au, mp3 | Generate frequency spectrogram images |
| 51 | **Audio Reverse** | wav, mp3, au | Reverse audio stream + flag keyword search |
| 52 | **SSTV** | wav | Decode SSTV (slow-scan television) images |
| 53 | **DTMF** | wav | Decode DTMF telephone tones via multimon-ng |

### 📄 Documents & Text

| Pri | Module | Formats | Description |
|-----|--------|---------|-------------|
| 32 | **Snow** | txt, html, css, js | Whitespace steganography decoder |
| 33 | **Zero Width** | txt, html, css, js | Detect zero-width Unicode character injection |
| 34 | **OleVBA** | doc, docx, xls, xlsx, ppt, pptx | Office macro analysis & VBA extraction |

### 📦 Archives

| Pri | Module | Formats | Description |
|-----|--------|---------|-------------|
| 55 | **ZIP Brute** | zip | Crack password-protected ZIPs (fcrackzip primary + unzip fallback) |

---

## Features

### 🔍 Smart Analysis
- **Polyglot Detection** — Identifies files with mismatched magic bytes ↔ extension; automatically fixes headers, strips appended junk, and saves a clean copy
- **Auto-Repair** — Fixes corrupted PNG IHDR CRCs, JPEG SOI markers, missing magic bytes
- **Re-Analysis Loop** — After repair, the file is automatically re-scanned by all modules
- **Partial Flag Detection** — When full flag patterns fail (e.g. digit-starting tails), fragments and tails are captured as fallback

### ⚙️ Workflow Engine
- **Event System** — Modules `emit()` findings; other modules subscribed via `MD_TRIGGERS` receive them
- **Priority Dispatch** — All 44 modules run in strict `MD_PRIORITY` order, no conflicts
- **Smart Wordlist** — Priority 5 module parses file metadata, strings, and filename to build a targeted password list used by Steghide, StegSeek, and ZIP Brute

### 📊 Output Formats
- **Default** — Clean flag/partial-flag display
- **`--verbose`** — Full per-module forensic report  
- **`--summary`** — One-liner per file (ideal for recursive `-r` scans)
- **`--json`** — Machine-readable: `{"file":"...", "flags":["..."], "partial_flags":["..."], "status":"found|partial|empty"}`

### 🛡 Security & Reliability
- **Read-Only Mode** — `--readonly` copies file to `/tmp` before any modification; original is never touched
- **Python Injection Protection** — All file paths passed to `python3 -c` use environment variables, eliminating code injection via malicious filenames
- **No Pipe Subshells** — Every `while read` loop uses process substitution `done < <(cmd)` — no lost data, no silent failures
- **Graceful Degradation** — Missing dependency? Module silently skips with a single `[SKIP]` line in verbose mode
- **Null-Byte Safety** — `LC_ALL=C strings` + `tr -d '\0'` throughout to suppress bash null-byte warnings

---

## Dependencies

```bash
# ── Core (strongly recommended) ──
apt install file xxd binwalk foremost steghide exiftool \
  ffmpeg sox tesseract-ocr python3-pip python3-pil

# ── Optional (auto-detected, skip if missing) ──
pip install stepic scipy matplotlib
gem install zsteg
apt install fcrackzip stegseek stegdetect outguess jpseek \
  multimon-ng mp3stego poppler-utils olevba snow p7zip-full
```

Run `stegoforge --doctor` to see which are available on your system.

---

## Output Hierarchy

```
~/Downloads/
└── <file>.png / .jpg / .gif     ← Polyglot Fixer output (ready to open)

output/sessions/<pid>/
├── carved/                       ← Extracted files (frames, wordlists, decoded payloads)
├── bitplanes/                    ← Bit plane images (planes 0–7)
├── spectrograms/                 ← Spectrogram images from audio modules
├── repaired/                     ← Repaired files (from Repair module + polyglot copy)
└── reports/                      ← (future: HTML/PDF forensic reports)
```

---

## Module API — Write Your Own

Adding a module takes 60 seconds. Drop a file in `modules/` with this template:

```bash
MD_NAME="MyModule"
MD_DESC="Description of what it does"
MD_TYPES="jpg png"
MD_PRIORITY=42
MD_PRODUCES="my_data flag"
MD_TRIGGERS="repair polyglot_fixed"

analyze_mymodule() {
    local f="$1" wl="$2"
    # Analyze $f, call emit() for findings
    emit "my_data" "Found something interesting: $data"
}
```

**Variables available:** `$f` (file path), `$wl` (wordlist), `$OUTDIR` (session output directory), `$FLAG_PATTERNS` (array of regexes), `$SMART_WL` (global smart wordlist).

---

## Test Suite

```bash
./tests/run_tests.sh
```

| Metric | Value |
|--------|-------|
| Total Tests | **28** |
| ✅ Passing | **22** |
| ❌ Failing | **0** |
| ⏭️ Skipped | **3** (QR/pyzbar · PDF images/reportlab · Disk forensics/mount — optional deps) |

---

## Behind the Scenes

- **Default output** shows only the flag or best partial match — use `-v` for the full forensic report
- **Polyglot fixer** saves repaired files to `~/Downloads/<file>.<correct_ext>` — you open it manually to see the flag
- **Smart wordlist (priority 5)** feeds all brute-force modules: Steghide, StegSeek, ZIP Brute
- **Repair module** sets `ANALYZE_THIS=1` to trigger a complete re-analysis pass on the fixed file
- **Flag patterns** (`picoCTF{}`, `HTB{}`, `THM{}`, `NCSE{}`, any `prefix{...}`) are defined in `config/flag_patterns.conf` — easy to extend
- **Flag tails** (fragments starting with a digit like `1n_pn9_&_pdf}`) don't match standard patterns — caught by the partial/tail fallback detector
- **Security**: No `python3 -c` uses string interpolation for filenames; all paths go through environment variables
- **Portability**: All `while read` loops use `done < <(cmd)` — never `cmd | while read` (pipe subshells drop all variables and `emit()` calls)

---

## License

**MIT** — Use it, modify it, ship it. No strings attached.

---

<p align="center">
  <sub>Built with ❤️ for the CTF community · <a href="https://github.com/id7eng/StegoForge">github.com/id7eng/StegoForge</a></sub>
</p>
