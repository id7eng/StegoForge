
<p align="center">
  <pre>
   _________ __        ________                   
  /   _____/  |_____  \_____  \___  ___  ___  ___ 
  \_____  \|  |  \__  \ /  ____/  / /  /  /  \  \
  /        \   |  / __ \ >     <  / /  /  /   >   \
 /_______  /___| (____  /___/\  \/ /  /  /___/  /\  \
         \/     \/     \/      \_/           \/  \_/
  </pre>
  <h1>StegoForge</h1>
  <p><strong>The All-in-One CTF Steganography & Forensics Arsenal</strong></p>
  <p>
    <a href="https://www.gnu.org/software/bash/"><img src="https://img.shields.io/badge/language-bash-4EAA25?logo=gnubash&logoColor=white" alt="Language"></a>
    <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue" alt="License"></a>
    <a href="https://github.com/id7eng/StegoForge/releases"><img src="https://img.shields.io/badge/version-1.3.3-green" alt="Version"></a>
    <img src="https://img.shields.io/badge/modules-44-orange" alt="Modules">
    <img src="https://img.shields.io/badge/tests-22%20PASS%200%20FAIL-brightgreen" alt="Tests">
    <img src="https://img.shields.io/badge/platform-linux%20%7C%20wsl-lightgrey" alt="Platform">
  </p>

  <table>
    <tr>
      <td><code>stegoforge image.png</code></td>
      <td>→ Extract & display flag</td>
    </tr>
    <tr>
      <td><code>stegoforge -v image.jpg</code></td>
      <td>→ Full forensic report</td>
    </tr>
    <tr>
      <td><code>stegoforge -r ~/CTF/</code></td>
      <td>→ Recursive directory scan</td>
    </tr>
  </table>
</p>

---

## 📋 Table of Contents

- [Quick Start](#rocket-quick-start)
- [Features](#-features)
- [Usage](#-cli-reference)
- [Module Catalogue](#-module-catalogue)
- [Architecture](#-architecture)
- [Output](#-output-hierarchy)
- [Test Suite](#-test-suite)
- [Module API](#-module-api)
- [Behind the Scenes](#-behind-the-scenes)
- [Contributing](#-contributing)

---

## 🚀 Quick Start

```bash
# 1. Install
git clone https://github.com/id7eng/StegoForge.git
cd StegoForge && chmod +x install.sh && ./install.sh

# 2. Scan a file
stegoforge suspicious.png

# 3. Full analysis
stegoforge -v unknown.bin --readonly

# 4. Scan entire challenge directory
stegoforge -r ~/ctf_challenges/ --summary
```

> **No root?** No problem — every module degrades gracefully. Missing tools are auto-skipped. Run `stegoforge --doctor` to see what's available.

---

## 🎯 Features

<table>
  <tr>
    <td width="50%">
      <h3>🔍 Smart Analysis</h3>
      <ul>
        <li><strong>Polyglot Detection</strong> — Catches files with mismatched magic bytes vs extension, fixes headers, strips appended garbage, saves clean copy to <code>~/Downloads/</code></li>
        <li><strong>Auto-Repair</strong> — Fixes broken PNG IHDR CRCs, JPEG SOI markers, missing magic bytes</li>
        <li><strong>Re-Analysis Loop</strong> — After repair, the engine automatically re-scans the fixed file</li>
        <li><strong>Partial Flag Detection</strong> — Catches fragments and tails when full patterns don't match</li>
        <li><strong>OCR Auto-Scale</strong> — Auto-upscales tiny images before Tesseract for better recognition</li>
      </ul>
    </td>
    <td width="50%">
      <h3>⚙️ Workflow Engine</h3>
      <ul>
        <li><strong>Event System</strong> — Modules <code>emit()</code> findings, others subscribed via <code>MD_TRIGGERS</code> react automatically</li>
        <li><strong>Priority Dispatch</strong> — All 44 modules execute in strict priority order, zero conflicts</li>
        <li><strong>Smart Wordlist</strong> — Priority 5 module parses metadata + strings + filename to build targeted passwords for Steghide, StegSeek, ZIP Brute</li>
        <li><strong>Gzip Auto-Decompress</strong> — Detects and decompresses gzip'd files before analysis</li>
      </ul>
    </td>
  </tr>
  <tr>
    <td width="50%">
      <h3>📊 Output Formats</h3>
      <ul>
        <li><strong>Default</strong> — Clean flag/partial-flag display</li>
        <li><strong><code>-v</code></strong> — Verbose per-module forensic report</li>
        <li><strong><code>--summary</code></strong> — <code>file → flag</code> one-liner (ideal for <code>-r</code>)</li>
        <li><strong><code>--json</code></strong> — Machine-readable: <code>{"file":"...", "flags":[...], "status":"found|partial|empty"}</code></li>
      </ul>
    </td>
    <td width="50%">
      <h3>🛡 Security & Reliability</h3>
      <ul>
        <li><strong>Read-Only Mode</strong> — <code>--readonly</code> copies to <code>/tmp</code>, original never touched</li>
        <li><strong>Python Injection Protection</strong> — All file paths use env vars, not string interpolation</li>
        <li><strong>No Pipe Subshells</strong> — Every <code>while read</code> uses <code>done < <(cmd)</code> — no silent data loss</li>
        <li><strong>Graceful Degradation</strong> — Missing deps? Module auto-skips, no crashes</li>
        <li><strong>Null-Byte Safety</strong> — <code>LC_ALL=C</code> + <code>tr -d '\0'</code> throughout</li>
      </ul>
    </td>
  </tr>
</table>

---

## 📖 CLI Reference

| Command | Description |
|---------|-------------|
| `stegoforge <file>` | Flag / partial flag only |
| `-v` | Full verbose analysis |
| `-w <wordlist>` | Custom password list for brute-force |
| `-r <dir>` | Recursive directory scan |
| `--json` | Structured JSON output |
| `--summary` | One-liner `file → flag` |
| `--readonly` | Operate on a copy |
| `--list` | Enumerate all 44 modules |
| `--doctor` | Dependency health check |
| `--version` | Display version |

---

## 📦 Module Catalogue

<details open>
<summary><b>🛠 Universal — 16 modules (every file type)</b></summary>

| Pri | Module | Description |
|-----|--------|-------------|
| 1 | **Repair** | Fix corrupted magic bytes, PNG IHDR CRC, JPEG headers |
| 2 | **Polyglot Fixer** | Detect magic-byte mismatch → fix, strip, save to `~/Downloads/` |
| 5 | **Smart Wordlist** | Context-aware password generator |
| 7 | **Binary Digits** | Decode ASCII `0`/`1` to binary |
| 8 | **Base64 Full** | Base64 + hex-encoded base64 decode |
| 10 | **Strings** | Keyword grep · auto base64/hex decode · flag + partial flag matching |
| 11 | **ROT Brute** | ROT1–25 + Atbash cipher |
| 16 | **EXIF Thumbnail** | Embedded EXIF thumbnail extraction |
| 22 | **OCR** | Tesseract OCR with auto-upscale |
| 28 | **Append Data** | Data after IEND / FFD9 / EOF markers |
| 50 | **PCAP Analysis** | HTTP objects · DNS · TCP streams · IPv6 · BPF filters |
| 52 | **Disk Forensics** | Loop-mount FAT/NTFS/ext4, extract artifacts |
| 60 | **Binwalk** | Embedded file detection |
| 70 | **Foremost** | File carving |
| 80 | **XOR Brute** | Single-byte XOR key recovery (0x00–0xFF) |
| 90 | **ADS Scan** | NTFS Alternate Data Streams |

</details>

<details open>
<summary><b>🖼 Image Analysis — 18 modules</b></summary>

| Pri | Module | Formats | Description |
|-----|--------|---------|-------------|
| 12 | **Video** | mp4, avi, mov, mkv, webm | Frame extraction, QR, accumulation, differencing |
| 15 | **StegDetect** | jpg, jpeg | Identify embedding tool |
| 20 | **Metadata** | jpg, png, bmp, gif, tiff, webp | Exif/ID3/XMP + acrostic analysis |
| 25 | **PNG CRC** | png | CRC check + brute-force dimensions |
| 30 | **Zsteg** | png, bmp | LSB detection |
| 35 | **QR** | jpg, jpeg, png, bmp, gif | QR/barcode scanning |
| 36 | **Stepic** | png, bmp | LSB decode (stepic) |
| 36 | **PDF Images** | pdf | Embedded raster image extraction |
| 37 | **GIF Palette** | gif | Per-frame palette analysis |
| 38 | **PDF Analysis** | pdf | Decompression, comments, post-%%EOF data |
| 39 | **StegSeek** | jpg, jpeg, bmp, wav | 100× faster steghide cracking |
| 40 | **Steghide** | jpg, jpeg, bmp, wav | Data extraction + brute-force |
| 42 | **OutGuess** | jpg, jpeg | OutGuess data extraction |
| 43 | **JPHide** | jpg, jpeg | JPHide data extraction |
| 44 | **F5** | jpg, jpeg | F5 data extraction |
| 45 | **Bit Plane** | png, bmp | Bit planes 0–7 as PNGs |
| 46 | **JPEG DQT** | jpg, jpeg | LSB from unused quantization tables |
| 47 | **Binary Border** | jpg, png, bmp, gif | Clockwise border pixel reading |
| 49 | **FFT Domain** | jpg, png, bmp, gif | Frequency domain analysis |

</details>

<details open>
<summary><b>🎵 Audio Analysis — 5 modules</b></summary>

| Pri | Module | Formats | Description |
|-----|--------|---------|-------------|
| 48 | **MP3Stego** | mp3 | MP3Stego extraction |
| 50 | **Spectrogram** | wav, au, mp3 | Spectrogram image generation |
| 51 | **Audio Reverse** | wav, mp3, au | Reverse + flag search |
| 52 | **SSTV** | wav | Slow-scan television decode |
| 53 | **DTMF** | wav | DTMF tone decode (multimon-ng) |

</details>

<details open>
<summary><b>📄 Documents & Text — 3 modules</b></summary>

| Pri | Module | Formats | Description |
|-----|--------|---------|-------------|
| 32 | **Snow** | txt, html, css, js | Whitespace steganography |
| 33 | **Zero Width** | txt, html, css, js | Zero-width Unicode detection |
| 34 | **OleVBA** | doc, docx, xls, xlsx, ppt, pptx | Office macro analysis |

</details>

<details open>
<summary><b>📦 Archives — 1 module</b></summary>

| Pri | Module | Formats | Description |
|-----|--------|---------|-------------|
| 55 | **ZIP Brute** | zip | Password cracking (fcrackzip + unzip fallback) |

</details>

---

## 🏗 Architecture

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

### How the Pipeline Works

```
Input File
    │
    ▼
┌────────────────────────────────────────────────────┐
│  1. Repair Phase (priority 1-2)                    │
│     → Fix corrupted headers                        │
│     → Detect polyglot (mismatched magic bytes)     │
│     → Save fixed copy to ~/Downloads/              │
└────────────────────┬───────────────────────────────┘
                     │ (if file was modified)
                     ▼
┌────────────────────────────────────────────────────┐
│  2. Preparation (priority 5)                       │
│     → Smart Wordlist extracts context passwords    │
│     → Gzip auto-decompress if needed               │
└────────────────────┬───────────────────────────────┘
                     ▼
┌────────────────────────────────────────────────────┐
│  3. Analysis Phase (priority 7-90)                 │
│     → 44 modules execute in strict order           │
│     → Each module calls emit() for findings        │
│     → Modules react to each other via triggers     │
└────────────────────┬───────────────────────────────┘
                     ▼
┌────────────────────────────────────────────────────┐
│  4. Reporting                                      │
│     → Collect all flags, partial flags, artifacts  │
│     → Output format (default/json/summary)         │
└────────────────────────────────────────────────────┘
```

---

## 📁 Output Hierarchy

```
~/Downloads/
└── <file>.png / .jpg / .gif     ← Polyglot Fixer: clean, openable files

output/sessions/<pid>/
├── carved/                       ← Extracted payloads, frames, wordlists
├── bitplanes/                    ← Bit plane images (planes 0–7)
├── spectrograms/                 ← Audio spectrogram images
├── repaired/                     ← Repair module output
└── reports/                      ← (coming soon: HTML/PDF forensic reports)
```

---

## 🧪 Test Suite

```bash
./tests/run_tests.sh
```

| Status | Count | Details |
|--------|-------|---------|
| ✅ **Passing** | **22** | All core modules verified |
| ❌ **Failing** | **0** | — |
| ⏭️ **Skipped** | **3** | QR (pyzbar), PDF images (reportlab), Disk forensics (mount) |
| **Total** | **28** | |

---

## 🔌 Module API — Write Your Own in 60 Seconds

```bash
MD_NAME="MyModule"
MD_DESC="Description of what it does"
MD_TYPES="jpg png"
MD_PRIORITY=42
MD_PRODUCES="my_data flag"
MD_TRIGGERS="repair polyglot_fixed"

analyze_mymodule() {
    local f="$1" wl="$2"
    emit "my_data" "Found something interesting: $data"
}
```

**Available variables:**
| Variable | Description |
|----------|-------------|
| `$f` | Path to file being analyzed |
| `$wl` | Wordlist path (from `-w` flag or Smart Wordlist) |
| `$OUTDIR` | Session output directory (`output/sessions/<pid>/`) |
| `$FLAG_PATTERNS` | Array of flag regex patterns from `config/flag_patterns.conf` |
| `$SMART_WL` | Global smart wordlist (populated by priority 5 module) |
| `$VERBOSE` | `true` if `-v` flag was passed |

---

## 🔬 Behind the Scenes

<details>
<summary><b>Security decisions that shaped this project</b></summary>

<br>

| Decision | Rationale |
|----------|-----------|
| **No `python3 -c` string interpolation** | All file paths passed via environment variables (`PYTHON_FILE`, `BITPLANE_FILE`, etc.) — prevents code injection from filenames containing quotes or backticks |
| **No pipe subshells** | `cmd \| while read` silently loses all variable assignments and `emit()` calls — every loop uses `done < <(cmd)` instead |
| **`LC_ALL=C` + `tr -d '\0'`** | Suppresses bash "null byte" warnings in every `strings` call across all modules |
| **Read-only mode by default** | The `--readonly` flag copies input to `/tmp` — the original file is never modified unless explicitly allowed |
| **Graceful degradation** | Every module checks dependencies at runtime; missing tools = one `[SKIP]` line, not a crash |

</details>

<details>
<summary><b>Edge cases handled</b></summary>

<br>

| Scenario | How it's handled |
|----------|-----------------|
| **Polyglot PNG+PDF** | Polyglot Fixer detects magic-byte mismatch, strips trailing data, saves to `~/Downloads/<file>.<correct_ext>` |
| **Corrupted magic bytes** | Repair module iterates known magic byte patterns, prepends missing bytes, triggers re-analysis |
| **Flag tails (e.g. `1n_pn9_&_pdf}`)** | Don't match standard patterns (digit-starting) — caught by `partial_flag` / `Tail` fallback |
| **ZIP with unknown password** | `fcrackzip` first (100× faster), falls back to `unzip` loop if not available |
| **OCR on tiny images** | Auto-upscales images <200px before passing to Tesseract |
| **Large files (>10MB)** | Smart Wordlist and Bit Plane skip large files to prevent hanging |
| **Gzip-compressed files** | Engine auto-detects gzip magic bytes, decompresses before analysis |
| **Binary `0`/`1` text files** | Binary Digits module detects all-0/1 content, reconstructs original binary |
| **NTFS Alternate Data Streams** | ADS Scan module enumerates streams on any mounted filesystem |

</details>

---

## 👥 Contributing

Contributions are welcome! Here's how:

1. **Add a module** — Use the [Module API](#-module-api—write-your-own-in-60-seconds) template
2. **Report a bug** — Open an [issue](https://github.com/id7eng/StegoForge/issues)
3. **Submit a PR** — Fork, branch, commit, push

### Development

```bash
# Run tests
./tests/run_tests.sh

# Check syntax of all modules
for f in modules/*.sh; do bash -n "$f" || echo "SYNTAX ERROR: $f"; done

# Check dependencies
./stegoforge --doctor
```

### Coding Standards

- All modules: `set -euo pipefail` within function scope (not globally — breaks graceful degradation)
- No `eval` anywhere
- No inline `python3 -c` with string-interpolated file paths — use env vars
- No `cmd | while read` — use `done < <(cmd)` instead
- Flag output via `emit "flag" "..."`, not `echo`

---

## 📜 License

**MIT** — Do whatever you want. Credit appreciated, not required.

---

<p align="center">
  <a href="https://github.com/id7eng/StegoForge">GitHub</a> ·
  <a href="https://github.com/id7eng/StegoForge/issues">Issues</a> ·
  <a href="https://github.com/id7eng/StegoForge/releases">Releases</a>
  <br><br>
  <sub>Built for the CTF community · No AI · No Payments · Just tools</sub>
</p>
