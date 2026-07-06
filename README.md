<p align="center">
<pre>
   _____ __                   ______                    
  / ___// /____  ____ _____  / ____/___  _________ ____ 
  \__ \/ __/ _ \/ __ `/ __ \/ /_  / __ \/ ___/ __ `/ _ \
 ___/ / /_/  __/ /_/ / /_/ / __/ / /_/ / /  / /_/ /  __/
/____/\__/\___/\__, /\____/_/    \____/_/   \__, /\___/ 
              /____/                       /____/       
</pre>
</p>

# StegoForge v2.0.0

**CTF Steganography & Forensics Toolkit** — 49 analysis modules, priority pipeline, decision engine, knowledge base.

[![Version](https://img.shields.io/badge/version-2.0.0-blue)](https://github.com/id7eng/StegoForge)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![Modules](https://img.shields.io/badge/modules-49-orange)]()
[![Language](https://img.shields.io/badge/language-bash-lightgrey)]()

---

## Table of Contents

- [About](#about)
- [Quick Start](#quick-start)
- [Features](#features)
- [Usage](#usage)
- [Modules](#modules)
- [Knowledge Base](#knowledge-base)
- [Output](#output)
- [Contributing](#contributing)
- [License](#license)

---

## About

StegoForge is an all-in-one steganography and forensics toolkit built for CTF competitions. It automates the detection and extraction of hidden data across **49 modules** covering images, audio, documents, archives, and raw forensics.

The tool uses a **priority-based pipeline** to run analysis modules in optimal order, a **decision engine** that selects the right modules per file type, and a **knowledge base** that learns from past writeups to improve future analysis.

No AI, no payments — just tools.

---

## Quick Start

```bash
git clone https://github.com/id7eng/StegoForge.git
cd StegoForge && chmod +x install.sh && ./install.sh
stegoforge image.png
```

**No root?** Every module auto-skips if tools are missing. Run `stegoforge --doctor` to check what's available.

### Other install methods

```bash
# Docker
docker build -t stegoforge . && docker run --rm -v $(pwd):/data stegoforge /data/image.png

# Direct
sudo ln -s "$PWD/stegoforge" /usr/local/bin/
```

---

## Features

| Feature | Description |
|---------|-------------|
| **Priority Pipeline** | 49 modules run in smart order, auto-skipping missing dependencies |
| **Decision Engine** | Rule-based module selection per file type (image, audio, archive, crypto) |
| **Knowledge Base** | SQLite learning system — tracks success rates, suggests optimal workflows |
| **Event System** | Modules emit findings, trigger other modules via subscription |
| **Auto-Repair** | Fixes broken PNG CRC, JPEG headers, missing magic bytes |
| **Smart Wordlist** | Generates context-aware passwords from metadata, strings, and KB |
| **Confidence Scoring** | Blends base scores with historical statistics for smarter selection |
| **Auto-Sync** | Imports relevant CTF writeups from configurable sources |
| **Loop Guard** | Prevents infinite re-analysis cycles |
| **Output Modes** | Default, verbose, JSON, summary, recursive |

---

## Usage

```bash
stegoforge image.png                  Analyze and show the flag
stegoforge -v image.jpg               Show module progress live
stegoforge -vv image.jpg              Show every command executed
stegoforge --json -r ~/challenges/    Recursive scan, JSON output
stegoforge -w rockyou.txt image.jpg   Use wordlist for brute-force
stegoforge --doctor                   Check system dependencies
stegoforge -l                         List all modules with priorities
stegoforge --readonly image.png       Analyze without modifying original

# Knowledge Base commands
stegoforge knowledge init             Initialize knowledge database
stegoforge knowledge sync --auto      Add default sources + fetch writeups
stegoforge knowledge suggest file     Get KB-based recommendations
stegoforge knowledge stats            Show tool success statistics
```

---

## Modules

### Universal (17)

| Pri | Module | Description |
|-----|--------|-------------|
| 1 | Repair | Fix broken magic bytes, PNG CRC, JPEG headers |
| 2 | Polyglot Detector | Detect & fix magic-byte mismatches |
| 5 | Smart Wordlist | Context-aware password generator |
| 7 | Binary Digits | Decode ASCII 0/1 to binary |
| 8 | Base64 Full | Decode base64 + hex-encoded base64 |
| 10 | Strings | Keyword grep, auto base64/hex, flag patterns |
| 11 | ROT Brute | Brute-force ROT1–25 + Atbash |
| 16 | EXIF Thumbnail | Extract embedded thumbnails |
| 22 | OCR | Tesseract OCR with auto-upscale |
| 28 | Append Data | Detect data after IEND/FFD9/EOF |
| 50 | PCAP Analysis | HTTP, DNS, TCP streams, BPF filters |
| 52 | Disk Forensics | Loop-mount FAT/NTFS/ext4 images |
| 60 | Binwalk | Embedded file detection |
| 70 | Foremost | File carving from raw images |
| 80 | XOR Brute | Single-byte XOR key recovery |
| 90 | ADS Scan | NTFS Alternate Data Streams |
| 99 | Flag Scanner | Aggressive flag pattern search |

### Image (22)

| Pri | Module | Formats | Description |
|-----|--------|---------|-------------|
| 12 | Video | mp4, avi, mov, mkv, webm | Frame extraction, QR, differencing |
| 13 | Quick Scan | jpg, png, bmp, gif | Rapid heuristic pre-scan |
| 14 | ImageMagick | jpg, png, bmp, gif, tiff, webp | Image properties, channel stats |
| 15 | StegDetect | jpg | Identify embedding tool |
| 17 | Cross LSB | png, bmp | Cross-color LSB analysis |
| 20 | Metadata | jpg, png, bmp, gif, tiff, webp | Exif/ID3/XMP + acrostic |
| 23 | PNG Check | png | Chunk-level validation |
| 25 | PNG CRC | png | CRC check + brute-force dimensions |
| 30 | Zsteg | png, bmp | LSB steganography detection |
| 35 | QR | jpg, png, bmp, gif | QR/barcode scanning |
| 36 | Stepic | png, bmp | LSB decode |
| 36 | PDF Images | pdf | Extract embedded raster images |
| 37 | GIF Palette | gif | Per-frame palette analysis |
| 38 | PDF Analysis | pdf | Decompression, comments, post-%%EOF |
| 39 | StegSeek | jpg, jpeg, bmp, wav | Fast steghide cracking |
| 40 | Steghide | jpg, jpeg, bmp, wav | Data extraction + brute-force |
| 42 | OutGuess | jpg | OutGuess extraction |
| 43 | JPHide | jpg | JPHide extraction |
| 44 | F5 | jpg | F5 extraction |
| 45 | Bit Plane | png, bmp | Extract bit planes 0–7 |
| 46 | JPEG DQT | jpg | LSB from quantization tables |
| 47 | Binary Border | jpg, png, bmp, gif | Border pixels as binary |
| 49 | FFT Domain | jpg, png, bmp, gif | Frequency domain analysis |

### Audio (6)

| Pri | Module | Formats | Description |
|-----|--------|---------|-------------|
| 41 | MP3Stego | mp3 | Extract MP3Stego hidden data |
| 48 | Spectrogram | wav, au, mp3 | Generate spectrogram images |
| 50 | Audio Reverse | wav, mp3, au | Reverse audio + flag search |
| 51 | SSTV | wav | Decode slow-scan TV images |
| 52 | DTMF | wav | Decode telephone tones |
| 53 | Steghide (WAV) | wav | Audio steghide extraction |

### Documents & Forensics (5)

| Pri | Module | Formats | Description |
|-----|--------|---------|-------------|
| 32 | Snow | txt, html, css, js | Whitespace steganography |
| 33 | Zero Width | txt, html, css, js | Zero-width Unicode detection |
| 34 | OleVBA | doc, docx, xls, ppt | Office macro analysis |
| 55 | ZIP Brute | zip | Password cracking (fcrackzip) |
| 80 | XOR Brute | any | Single-byte XOR brute-force |

---

## Knowledge Base

StegoForge includes a SQLite-based learning system:

```bash
stegoforge knowledge init              # Create database
stegoforge knowledge sync --auto       # Import relevant writeups
stegoforge knowledge suggest file.png  # Get analysis recommendations
stegoforge knowledge stats png         # Tool success statistics
stegoforge knowledge list-sources      # Show configured sources
```

The KB tracks which tools work for each file type, builds confidence scores, and stores evidence from past sessions to guide future analysis.

---

## Output

```
output/sessions/<pid>/
  carved/       Extracted/carved files
  bitplanes/    Bit plane images (0–7)
  spectrograms/ Spectrogram images
  repaired/     Repaired files
  reports/      KB evidence logs
```

Output formats: `default` (flag only), `-v` (verbose), `--json`, `--summary`.

---

## Contributing

Drop a new module in `modules/`:

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

See existing modules for reference. No `eval`, no unsafe Python inline code.

---

## License

MIT — Use it, modify it, ship it.

---

<p align="center">
  <a href="https://github.com/id7eng/StegoForge">GitHub</a> ·
  <a href="https://github.com/id7eng/StegoForge/issues">Issues</a> ·
  <a href="https://github.com/id7eng/StegoForge/releases">Releases</a><br>
  <sub>Built for the CTF community</sub>
</p>
