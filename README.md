# StegoForge

Professional CTF Steganography & Forensics Toolkit — **34 modules** covering JPEG, PNG, GIF, BMP, WAV, MP3, MP4, PDF, Office, ZIP, and more.

```bash
stegoforge image.png                    # flag only
```

## Installation

```bash
git clone https://github.com/id7eng/StegoForge.git
cd StegoForge && chmod +x install.sh && ./install.sh
```

Then run from anywhere: `stegoforge image.png`

## Usage

| Command | What it does |
|---------|-------------|
| `stegoforge image.png` | Show flag only |
| `stegoforge -v image.jpg` | Full verbose analysis |
| `stegoforge -w wordlist.txt image.jpg` | Brute-force passwords |
| `stegoforge -r ~/CTF/` | Scan directory recursively |
| `stegoforge --json file.png` | JSON output |
| `stegoforge --summary file.png` | Summary output (file → flag) |
| `stegoforge --readonly file.png` | Don't modify original |
| `stegoforge --list` | List all 34 modules |
| `stegoforge --doctor` | Check installed tools |

## All 34 Modules

### Universal (every file type)

| Priority | Module | What it does |
|----------|--------|-------------|
| 5 | Smart Wordlist | Generates passwords from file metadata/strings/filename |
| 10 | Strings | Keyword search + Base64 decode + flag pattern matching |
| 60 | Binwalk | Detect embedded files |
| 70 | Foremost | File carving / recovery |
| 80 | XOR Brute | Single-byte XOR key recovery (0x00–0xFF) |
| 90 | ADS Scan | NTFS Alternate Data Streams |

### Image Analysis

| Priority | Module | Formats | What it does |
|----------|--------|---------|-------------|
| 1 | Repair | data | Fix corrupted magic bytes, PNG IHDR, JPEG headers |
| 12 | Video | mp4, avi, mov, mkv, webm | Frame extraction, QR detection, frame accumulation, differencing |
| 15 | StegDetect | jpg, jpeg | Detect JPEG tool used (jphide, outguess, jsteg, F5) |
| 20 | Metadata | jpg, jpeg, png, bmp, gif, tiff, webp | Extract Exif/ID3/XMP |
| 25 | PNG CRC | png | Verify CRC, brute-force correct dimensions |
| 30 | Zsteg | png, bmp | LSB steganography detection |
| 35 | QR | jpg, jpeg, png, bmp, gif | QR code scanning |
| 36 | Stepic | png, bmp | LSB decode via stepic library (picoCTF 2025) |
| 37 | GIF Palette | gif | Local frame palette analysis |
| 39 | StegSeek | jpg, jpeg, bmp, wav | Fast steghide password cracking (100x faster) |
| 40 | Steghide | jpg, jpeg, bmp, wav | Extract data + brute-force (uses stegseek if available) |
| 42 | OutGuess | jpg, jpeg | Extract data from outguess-embedded JPEGs |
| 43 | JPHide | jpg, jpeg | Extract data + brute-force |
| 44 | F5 | jpg, jpeg | Extract data from F5-embedded JPEGs |
| 45 | Bit Plane | png, bmp | Extract bit planes 0–7 as PNGs |
| 46 | JPEG DQT | jpg, jpeg | LSB extraction from unused quantization tables |
| 47 | Binary Border | jpg, jpeg, png, bmp, gif | Read border pixels clockwise as binary data |
| 49 | FFT Domain | jpg, jpeg, png, bmp, gif | Frequency domain analysis (FFT pattern detection) |

### Audio Analysis

| Priority | Module | Formats | What it does |
|----------|--------|---------|-------------|
| 48 | MP3Stego | mp3 | Extract hidden data |
| 50 | Spectrogram | wav, au, mp3, wave | Generate spectrogram image |
| 51 | Audio Reverse | wav, mp3, au | Reverse audio and search for flags |
| 52 | SSTV | wav | Decode SSTV images from audio |
| 53 | DTMF | wav | Decode phone tones (multimon-ng) |

### Documents & Text

| Priority | Module | Formats | What it does |
|----------|--------|---------|-------------|
| 32 | Snow | txt, html, css, js | Whitespace steganography decoder |
| 33 | Zero Width | txt, html, css, js | Detect zero-width Unicode characters |
| 34 | OleVBA | doc, docx, xls, xlsx, ppt, pptx | Office macro analysis |
| 38 | PDF Analysis | pdf | Multi-layer PDF analysis, comments, post-%%EOF data |

### Archives

| Priority | Module | Formats | What it does |
|----------|--------|---------|-------------|
| 55 | ZIP Brute | zip | Crack password-protected ZIPs |

## Features

| Feature | Description |
|---------|-------------|
| Smart Wordlist | Extracts passwords from file metadata/strings/filename before brute-force |
| Workflow Engine | Modules chain via `emit()` / `MD_TRIGGERS` (repair → metadata → decode) |
| Priority System | Modules run in order of `MD_PRIORITY` |
| JSON Output | `--json` produces structured `{"file":"...","flags":["..."],"status":"found"}` |
| Summary Output | `--summary` shows `file → flag` (perfect for recursive scans) |
| Read-Only Mode | `--readonly` works on a copy in /tmp, original stays intact |
| Auto-Repair | Fixes corrupted magic bytes and PNG CRC before analysis |
| Flag Patterns | Detects `picoCTF{}`, `HTB{}`, `THM{}`, `NCSE{}`, and any `prefix{...}` format |
| No AI / No Payments | All tools are free CLI utilities and Python libraries |

## Dependencies

```bash
# Core
apt install file xxd binwalk foremost steghide exiftool \
  ffmpeg sox python3-pip python3-pil

# Optional
pip install stepic scipy matplotlib
gem install zsteg
apt install stegseek stegdetect outguess jpseek \
  multimon-ng mp3stego pdftotext olevba snow
```

## Output Structure

```
output/sessions/<pid>/
├── carved/         ← Extracted files (frames, wordlists, decoded)
├── bitplanes/      ← Bit plane images
├── spectrograms/   ← Spectrogram images
├── repaired/       ← Fixed files
└── reports/        ← (future)
```

## Module API

Drop a file in `modules/`:

```bash
MD_NAME="MyModule"
MD_DESC="Description"
MD_TYPES="jpg png"
MD_PRIORITY=42
MD_PRODUCES="my_data flag"

analyze_mymodule() {
    local f="$1" wl="$2"
    # Analyze file, call emit() for findings
    emit "my_data" "Found something: $data"
}
```

## Test Suite

```bash
./tests/run_tests.sh
```

**Current:** 17 PASS, 0 FAIL, 1 SKIP (QR needs pyzbar)

## Notes

- Default output shows only the flag. Use `-v` for full analysis.
- Smart Wordlist runs first (priority 5) and its output is used by Steghide/StegSeek/ZIP Brute.
- Repair module fixes files before other modules process them.
- All modules gracefully skip if their dependencies are not installed.

## License

MIT
