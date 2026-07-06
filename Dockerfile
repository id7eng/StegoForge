FROM ubuntu:24.04

LABEL description="StegoForge - CTF Steganography & Forensics Toolkit"
LABEL version="1.3.4"

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash file xxd binutils coreutils \
    python3 python3-pip python3-pil python3-scipy python3-matplotlib python3-numpy \
    exiftool binwalk foremost steghide ffmpeg sox tesseract-ocr \
    fcrackzip pngcheck sleuthkit tshark poppler-utils \
    zbar-tools libzbar-dev multimon-ng stegsnow p7zip-full \
    outguess attr dosfstools unzip \
    && rm -rf /var/lib/apt/lists/*

RUN pip3 install stepic pyzbar reportlab --break-system-packages 2>/dev/null || \
    pip3 install stepic pyzbar reportlab 2>/dev/null || true

RUN apt-get update && apt-get install -y --no-install-recommends ruby ruby-dev && \
    gem install zsteg 2>/dev/null; \
    apt-get remove -y ruby-dev && apt-get autoremove -y; \
    rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y --no-install-recommends golang-go && \
    git clone https://github.com/lukechampine/jsteg.git /tmp/jsteg && \
    cd /tmp/jsteg && go build -o /usr/local/bin/jsteg . 2>/dev/null; \
    rm -rf /tmp/jsteg; \
    apt-get remove -y golang-go && apt-get autoremove -y; \
    rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y --no-install-recommends build-essential cmake libjpeg-dev && \
    git clone https://github.com/abeluck/stegdetect.git /tmp/stegdetect && \
    cd /tmp/stegdetect && ./configure --quiet && make --silent && make install 2>/dev/null; \
    rm -rf /tmp/stegdetect; \
    git clone https://github.com/fabienpe/MP3Stego.git /tmp/mp3stego && \
    cd /tmp/mp3stego && chmod +x MP3Stego && cp MP3Stego /usr/local/bin/ 2>/dev/null; \
    rm -rf /tmp/mp3stego; \
    apt-get remove -y build-essential cmake libjpeg-dev && apt-get autoremove -y; \
    rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/RickdeJager/stegseek.git /tmp/stegseek && \
    cd /tmp/stegseek && mkdir build && cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release .. && make --silent && make install 2>/dev/null; \
    rm -rf /tmp/stegseek

COPY . /opt/stegoforge

RUN rm -rf /opt/stegoforge/output /opt/stegoforge/tests /opt/stegoforge/report-*.html /opt/stegoforge/report-*.markdown /opt/stegoforge/knowledge.db /opt/stegoforge/knowledge/auto_sync.log

RUN ln -sf /opt/stegoforge/stegoforge /usr/local/bin/stegoforge

WORKDIR /work

ENTRYPOINT ["/opt/stegoforge/stegoforge"]
