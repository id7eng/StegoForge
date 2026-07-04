FROM ubuntu:24.04

LABEL description="StegoForge - CTF Steganography & Forensics Toolkit"
LABEL version="1.3.4"

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash file xxd binutils coreutils \
    python3 python3-pip python3-pil python3-scipy python3-matplotlib \
    exiftool binwalk foremost steghide ffmpeg sox tesseract-ocr \
    fcrackzip pngcheck sleuthkit tshark poppler-utils \
    zbar-tools multimon-ng stegsnow p7zip-full \
    outguess attr \
    git ca-certificates ruby ruby-dev build-essential cmake golang \
    && rm -rf /var/lib/apt/lists/*

RUN pip install stepic pyzbar --break-system-packages 2>/dev/null || \
    pip install stepic pyzbar 2>/dev/null || true

RUN gem install zsteg 2>/dev/null || true

# stegdetect
RUN git clone https://github.com/abeluck/stegdetect.git /tmp/stegdetect 2>/dev/null; \
    cd /tmp/stegdetect && ./configure && make && make install 2>/dev/null || true; \
    rm -rf /tmp/stegdetect

# mp3stego
RUN git clone https://github.com/fabienpe/MP3Stego.git /tmp/mp3stego 2>/dev/null; \
    cd /tmp/mp3stego && chmod +x MP3Stego && cp MP3Stego /usr/local/bin/ 2>/dev/null || true; \
    rm -rf /tmp/mp3stego

# jpseek (jsteg/jphide) — compile from source
RUN git clone https://github.com/lukechampine/jsteg.git /tmp/jsteg 2>/dev/null; \
    cd /tmp/jsteg && go build -o /usr/local/bin/jsteg . 2>/dev/null || true; \
    rm -rf /tmp/jsteg

# stegseek
RUN git clone https://github.com/RickdeJager/stegseek.git /tmp/stegseek 2>/dev/null; \
    cd /tmp/stegseek && mkdir build && cd build && \
    cmake .. && make && make install 2>/dev/null || true; \
    rm -rf /tmp/stegseek

COPY . /opt/stegoforge

RUN ln -sf /opt/stegoforge/stegoforge /usr/local/bin/stegoforge

WORKDIR /work

ENTRYPOINT ["/opt/stegoforge/stegoforge"]
