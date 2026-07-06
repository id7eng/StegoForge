
   _____ __                   ______                    
  / ___// /____  ____ _____  / ____/___  _________ ____ 
  \__ \/ __/ _ \/ __ `/ __ \/ /_  / __ \/ ___/ __ `/ _ \
 ___/ / /_/  __/ /_/ / /_/ / __/ / /_/ / /  / /_/ /  __/
/____/\__/\___/\__, /\____/_/    \____/_/   \__, /\___/ 
              /____/                       /____/       

# StegoForge **v2.0.0** — CTF Steganography & Forensics Toolkit

49 analysis modules · Priority-based pipeline · Decision Engine · Knowledge Base · Event-driven architecture

---

## Quick Start

```bash
git clone https://github.com/id7eng/StegoForge.git
cd StegoForge && chmod +x install.sh && ./install.sh
stegoforge image.png
```

---

## What's New in v2.0

| Feature | Description |
|---------|-------------|
| **Decision Engine** | Rule-based module selection per file type (image/audio/archive/crypto/repair) with confidence scoring |
| **Priority System** | Two-level scheduling — static module priorities + dynamic file-type priority boosts |
| **Pipeline Orchestrator** | Multi-phase pipeline: repair → knowledge-guided analysis → emit → decide → output |
| **Knowledge Base** | SQLite-powered learning: stores tools per file type, tracks success rates, suggests optimal workflows |
| **Confidence Scoring** | Blends hardcoded base with historical statistics for smarter module selection |
| **Auto-Sync** | Automated writeup import from CTF sources, relevance-filtered against installed modules |
| **Smart Wordlist (L4)** | Context-aware password generation from metadata, strings, and KB password history |
| **Loop Guard** | Cycle detection prevents infinite re-analysis loops |
| **Module API v2** | Event-driven: modules `emit()` typed findings, subscribed modules react via triggers |

---

## Architecture

```
                    ┌─────────────────────────────────┐
                    │          stegoforge              │
                    │         (entry point)            │
                    └──────────────┬──────────────────┘
                                   │
                    ┌──────────────▼──────────────────┐
                    │          engine.sh               │
                    │    Workflow coordinator          │
                    │  File detection · Loop guard     │
                    └──────────────┬──────────────────┘
                                   │
                    ┌──────────────▼──────────────────┐
                    │       orchestrator.sh            │
                    │   Pipeline execution manager     │
                    │  Phase 1-4 · KB-guided dispatch  │
                    └───┬──────────┬──────────┬───────┘
                        │          │          │
             ┌──────────▼──┐  ┌────▼────┐  ┌─▼──────────┐
             │  Priority   │  │ Decision│  │  Confidence │
             │  System     │  │ Engine  │  │  Scoring    │
             │  priority.sh│  │decision.│  │confidence.sh│
             │  + boosts   │  │ sh+rules│  │             │
             └─────────────┘  └─────────┘  └─────────────┘
                        │          │
             ┌──────────▼──────────▼────────────────────┐
             │           49 Analysis Modules             │
             │  Repair → Polyglot → Metadata → Steghide │
             │  Zsteg → Foremost → Binwalk → XOR → ... │
             │  Event-driven via emit()/MD_TRIGGERS     │
             └────────────────┬─────────────────────────┘
                              │
             ┌────────────────▼─────────────────────────┐
             │         Knowledge Base (SQLite)           │
             │  Writeups · Statistics · Evidence · Sync  │
             │  kbe.sh · sync.sh · db.sh · inference.sh │
             └───────────────────────────────────────────┘
```

### Pipeline Flow

1. **Phase 1 — Repair**: Fix broken headers, CRC, polyglot detection
2. **Phase 2 — Prep**: Smart wordlist generation, gzip decompress
3. **Phase 3 — Analysis**: Priority-ordered execution with KB-guided suggestions
4. **Phase 4 — Report**: Flag collection, JSON/summary/verbose output

---

## 49 Analysis Modules

### Universal (16)

| Pri | Module | Description |
|-----|--------|-------------|
| 1 | Repair | Fix corrupted magic bytes, PNG IHDR CRC, JPEG headers |
| 2 | Polyglot Detector | Detect magic-byte mismatch → fix, strip, save clean copy |
| 5 | Smart Wordlist | Context-aware password generator (4 layers) |
| 7 | Binary Digits | Decode ASCII 0/1 text to binary |
| 8 | Base64 Full | Decode base64 + hex-encoded base64 |
| 10 | Strings | Keyword grep · auto base64/hex · flag patterns |
| 11 | ROT Brute | Brute-force ROT1–25 + Atbash cipher |
| 16 | EXIF Thumbnail | Extract & analyze embedded EXIF thumbnails |
| 22 | OCR | Tesseract OCR with auto-upscale |
| 28 | Append Data | Detect data appended after IEND/FFD9/EOF |
| 50 | PCAP Analysis | HTTP objects · DNS · TCP streams · BPF filters |
| 52 | Disk Forensics | Loop-mount FAT/NTFS/ext4 images |
| 60 | Binwalk | Detect & extract embedded files |
| 70 | Foremost | File carving from raw images |
| 80 | XOR Brute | Single-byte XOR key recovery (0x00–0xFF) |
| 90 | ADS Scan | NTFS Alternate Data Stream enumeration |
| 99 | Flag Scanner | Aggressive flag pattern search across all data |

### Image Analysis (22)

| Pri | Module | Formats | Description |
|-----|--------|---------|-------------|
| 12 | Video | mp4, avi, mov, mkv, webm | Frame extraction, QR, accumulation, differencing |
| 13 | Quick Scan | jpg, png, bmp, gif | Rapid heuristic pre-scan |
| 14 | ImageMagick | jpg, png, bmp, gif, tiff, webp | Image properties, channel stats |
| 15 | StegDetect | jpg, jpeg | Identify embedding tool |
| 17 | Cross LSB | png, bmp | Cross-color LSB analysis |
| 20 | Metadata | jpg, png, bmp, gif, tiff, webp | Exif/ID3/XMP + acrostic |
| 23 | PNG Check | png | Chunk-level validation |
| 25 | PNG CRC | png | CRC check + brute-force dimensions |
| 30 | Zsteg | png, bmp | LSB steganography detection |
| 35 | QR | jpg, jpeg, png, bmp, gif | QR/barcode scanning |
| 36 | Stepic | png, bmp | LSB decode via stepic |
| 36 | PDF Images | pdf | Extract embedded raster images |
| 37 | GIF Palette | gif | Per-frame palette analysis |
| 38 | PDF Analysis | pdf | Decompression, comments, post-%%EOF |
| 39 | StegSeek | jpg, jpeg, bmp, wav | 100x faster steghide cracking |
| 40 | Steghide | jpg, jpeg, bmp, wav | Data extraction + brute-force |
| 42 | OutGuess | jpg, jpeg | OutGuess data extraction |
| 43 | JPHide | jpg, jpeg | JPHide data extraction |
| 44 | F5 | jpg, jpeg | F5 data extraction |
| 45 | Bit Plane | png, bmp | Extract bit planes 0–7 as PNGs |
| 46 | JPEG DQT | jpg, jpeg | LSB from unused quantization tables |
| 47 | Binary Border | jpg, png, bmp, gif | Read border pixels as binary |
| 49 | FFT Domain | jpg, png, bmp, gif | Frequency domain analysis |

### Audio Analysis (6)

| Pri | Module | Formats | Description |
|-----|--------|---------|-------------|
| 41 | MP3Stego | mp3 | Extract MP3Stego hidden data |
| 48 | Spectrogram | wav, au, mp3 | Generate spectrogram image |
| 50 | Audio Reverse | wav, mp3, au | Reverse audio + flag search |
| 51 | SSTV | wav | Decode slow-scan television images |
| 52 | DTMF | wav | Decode telephone tones |
| 53 | Steghide (WAV) | wav | Audio steghide extraction |

### Documents & Text (3)

| Pri | Module | Formats | Description |
|-----|--------|---------|-------------|
| 32 | Snow | txt, html, css, js | Whitespace steganography |
| 33 | Zero Width | txt, html, css, js | Zero-width Unicode detection |
| 34 | OleVBA | doc, docx, xls, xlsx, ppt, pptx | Office macro analysis |

### Archives (1)

| Pri | Module | Formats | Description |
|-----|--------|---------|-------------|
| 55 | ZIP Brute | zip | Crack passwords (fcrackzip + unzip) |

### Carving & Recovery (2)

| Pri | Module | Formats | Description |
|-----|--------|---------|-------------|
| 60 | Binwalk | raw, bin | Embedded file detection |
| 70 | Foremost | raw, bin, img | File carving |

### Crypto (1)

| Pri | Module | Formats | Description |
|-----|--------|---------|-------------|
| 80 | XOR Brute | any | Single-byte XOR brute-force |

---

## Decision Engine

Modules are selected dynamically based on file type. Rule files in `core/decision_rules/` define which modules apply:

- **image.sh** — 30+ image analysis modules
- **audio.sh** — 6 audio analysis modules  
- **archive.sh** — ZIP brute-force, carving
- **crypto.sh** — XOR, ROT, base64
- **repair.sh** — File repair, polyglot detection
- **kb.sh** — Knowledge Base suggested modules

Each module has a **confidence score** (0–100) that blends hardcoded base with KB success statistics.

---

## Knowledge Base

SQLite-powered learning system (`knowledge/`):

| Component | Description |
|-----------|-------------|
| `db.sh` | Database interface (18 functions) |
| `schema.sql` | Tables: writeups, knowledge, statistics, sources, evidence, sync_log |
| `sync.sh` | Auto-sync writeups from CTF sources (relevance-filtered) |
| `kbe.sh` | CLI interface (19 commands) |
| `inference.sh` | Tool suggestion engine |

```bash
stegoforge knowledge init          # Initialize database
stegoforge knowledge sync --auto   # Import relevant writeups
stegoforge knowledge suggest file.png  # Get KB recommendations
stegoforge knowledge stats png     # Show tool success stats
```

---

## Output

```
output/sessions/<pid>/
  carved/         Extracted/carved files
  bitplanes/      Bit plane images (0–7)
  spectrograms/   Spectrogram images
  repaired/       Repaired files
  reports/        KB evidence logs
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

**Environment variables:** `$f`, `$wl`, `$OUTDIR`, `$FLAG_PATTERNS`, `$SMART_WL`, `$VERBOSE`, `$VERBOSE_CMD`, `$JSON`, `$SUMMARY`

---

## Coding Standards

- No `eval`, no unsafe `python3 -c`
- Flag output via `emit "flag" "..."`, never `echo`
- Modules gracefully skip missing deps, never crash
- Pipeline-safe: no data loss, no infinite loops (protected by Loop Guard)

---

## License

MIT — Use it, modify it, ship it.

---

<p align="center">
  <a href="https://github.com/id7eng/StegoForge">GitHub</a> ·
  <a href="https://github.com/id7eng/StegoForge/issues">Issues</a> ·
  <a href="https://github.com/id7eng/StegoForge/releases">Releases</a><br>
  <sub>Built for the CTF community · No AI · No Payments · Just tools</sub>
</p>
