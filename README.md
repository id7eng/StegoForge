# StegoForge

Professional CTF Steganography & Forensics Toolkit — auto-repair, analyse, and extract flags in one command.

## Installation

```bash
chmod +x install.sh && ./install.sh
```

Or use directly: `./stegoforge image.png`

Then run from anywhere: `stegoforge image.png`

## Features

- **Auto-repair** — Fix corrupted magic bytes (JPEG, PNG, GIF, PDF, ZIP)
- **Keyword hunt** — Search for flags, secrets, and Base64 in any file
- **LSB analysis** — zsteg for PNG/BMP, plus bit plane extraction
- **Steghide** — Extract hidden data + brute-force passwords
- **File carving** — Binwalk + Foremost for embedded files
- **PNG CRC fix** — Detect and brute-force modified image dimensions
- **XOR brute** — Single-byte XOR key recovery
- **QR detection** — Read QR codes from images
- **Audio analysis** — Spectrogram generation
- **NTFS ADS** — Alternate Data Stream scanning
- **ZIP cracking** — fcrackzip integration
- **Workflow engine** — Modules chain intelligently (e.g., repair → metadata → found base64 → decode)

## Supported Formats

| Format | Modules applied |
|--------|----------------|
| JPEG/JPG | Metadata, Strings, Steghide, Binwalk, Foremost, QR, XOR |
| PNG | Metadata, Strings, Zsteg, Binwalk, Foremost, QR, PNG CRC, Bit Plane, XOR |
| BMP | Metadata, Strings, Zsteg, Steghide, Binwalk, Bit Plane, XOR |
| GIF | Metadata, Strings, QR, Binwalk, Foremost, XOR |
| WAV/MP3 | Spectrogram, Strings, Binwalk, Steghide |
| ZIP/RAR/7z | Strings, Binwalk, Foremost, ZIP Brute |
| PDF | Metadata, Strings, Binwalk |
| Any file | Strings, Binwalk, Foremost, XOR Brute, ADS Scan |

## Modules

| Name | Priority | Types | Produces |
|------|----------|-------|----------|
| Repair | 1 | data | repaired_file |
| Strings | 10 | * | keyword, base64_string |
| Metadata | 20 | jpg/png/bmp/gif | metadata_value |
| PNG CRC | 25 | png | crc_fixed, dims_found |
| Zsteg | 30 | png/bmp | lsb_data, flag |
| QR | 35 | jpg/png/bmp/gif | qr_data |
| Steghide | 40 | jpg/bmp/wav | steghide_data, password |
| Bit Plane | 45 | png/bmp | bitplane |
| Spectrogram | 50 | wav/mp3 | spectrogram |
| ZIP Brute | 55 | zip | zip_password, extracted |
| Binwalk | 60 | * | embedded_file |
| Foremost | 70 | * | carved_file |
| XOR Brute | 80 | * | xor_key, decoded |
| ADS Scan | 90 | * (NTFS) | ads_found |

## Usage

```bash
stegoforge image.png                    # flag only
stegoforge -v image.jpg                 # full analysis
stegoforge -w rockyou.txt image.jpg     # steghide + zip brute
stegoforge -r ~/CTF/                    # scan directory
stegoforge --list                       # show all modules
stegoforge --doctor                     # check dependencies
stegoforge -o ~/results/ -j image.png   # JSON + custom output
```

## Output Structure

```
output/
└── sessions/
    └── <pid>/
        ├── carved/         ← Binwalk/Foremost/ZIP extractions
        ├── bitplanes/      ← Bit plane PNG images
        ├── spectrograms/   ← Spectrogram images
        ├── repaired/       ← Fixed files
        └── reports/        ← (future: HTML/PDF reports)
```

## Dependencies

**Core:** `bash file xxd strings md5sum sha256sum`

**Optional:** `exiftool binwalk foremost steghide zsteg fcrackzip python3-pil python3-pyzbar`

```bash
apt install exiftool binwalk foremost steghide fcrackzip python3-pil
gem install zsteg
pip install pyzbar scipy matplotlib
```

## Roadmap

See [ROADMAP.md](ROADMAP.md) for upcoming features.

## Contributing

Add a module: drop a file in `modules/` with `MD_PRIORITY`, `MD_TYPES`, and `analyze_<name>()`.

## License

MIT
