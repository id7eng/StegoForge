```
   _____ __                   ______                    
  / ___// /____  ____ _____  / ____/___  _________ ____ 
  \__ \/ __/ _ \/ __ `/ __ \/ /_  / __ \/ ___/ __ `/ _ \
 ___/ / /_/  __/ /_/ / /_/ / __/ / /_/ / /  / /_/ /  __/
/____/\__/\___/\__, /\____/_/    \____/_/   \__, /\___/ 
              /____/                       /____/       
```

# StegoForge **v2.0.0**

CTF Steganography & Forensics Toolkit · 49 modules

---

## Table of Contents

- [Quick Start](#quick-start)
- [Features](#features)
- [Usage](#usage)
- [Modules](#modules)
- [Output](#output)
- [Tests](#tests)
- [License](#license)

---

## Quick Start

```bash
git clone https://github.com/id7eng/StegoForge.git
cd StegoForge && chmod +x install.sh && ./install.sh
stegoforge image.png
```

---

## Features

| Feature | What it does |
|---------|-------------|
| Priority Pipeline | Modules run in smart order, auto-skipping missing tools |
| Decision Engine | Chooses the right modules for each file type |
| Knowledge Base | Learns from past writeups to suggest better analysis |
| Auto-Repair | Fixes broken PNG, JPEG, and other corrupted files |
| Smart Wordlist | Generates targeted passwords from metadata & strings |
| Auto-Sync | Fetches relevant CTF writeups automatically |
| JSON / Summary / Verbose | Multiple output formats |

---

## Usage

```bash
stegoforge image.png              → Analyze and find hidden data
stegoforge -v image.jpg           → Show module progress live
stegoforge --json -r ~/CTF/       → Recursive scan, JSON output
stegoforge -w wordlist.txt file   → Use custom wordlist
stegoforge --doctor               → Check installed dependencies
stegoforge knowledge sync --auto  → Import relevant writeups
stegoforge knowledge suggest file → Get analysis recommendations
```

---

## Modules

**Universal (16):** Repair · Polyglot Detector · Smart Wordlist · Binary Digits · Base64 · Strings · ROT Brute · EXIF Thumbnail · OCR · Append Data · PCAP Analysis · Disk Forensics · Binwalk · Foremost · XOR Brute · ADS Scan · Flag Scanner

**Image (22):** Video · Quick Scan · ImageMagick · StegDetect · Cross LSB · Metadata · PNG Check · PNG CRC · Zsteg · QR · Stepic · PDF Images · GIF Palette · PDF Analysis · StegSeek · Steghide · OutGuess · JPHide · F5 · Bit Plane · JPEG DQT · Binary Border · FFT Domain

**Audio (6):** MP3Stego · Spectrogram · Audio Reverse · SSTV · DTMF · Audio Steghide

**Documents (3):** Snow · Zero Width · OleVBA

**Archive (1):** ZIP Brute

**Crypto (1):** XOR Brute

---

## Output

```
output/sessions/<pid>/
  carved/       Extracted/carved files
  bitplanes/    Bit plane images
  spectrograms/ Spectrogram images
  repaired/     Repaired files
```

---

## Tests

```bash
./tests/run_tests.sh
```

---

## License

MIT

---

<p align="center">
  <a href="https://github.com/id7eng/StegoForge">GitHub</a> ·
  <a href="https://github.com/id7eng/StegoForge/issues">Issues</a><br>
  <sub>Built for the CTF community</sub>
</p>
