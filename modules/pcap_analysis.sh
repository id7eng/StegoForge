MD_NAME="PCAP Analysis"
MD_DESC="Analyze network packet captures: HTTP objects, DNS, payload strings"
MD_TYPES="pcap pcapng"
MD_DEPS="tshark"
MD_PRIORITY=50
MD_PRODUCES="pcap_object flag"

analyze_pcap_analysis() {
    local f="$1"
    local ftype=$(file -b --mime-type "$f" 2>/dev/null)

    if [[ "$ftype" != "application/vnd.tcpdump.pcap" ]] && [[ "$ftype" != "application/x-pcapng" ]]; then
        [[ "$f" =~ \.(pcap|pcapng)$ ]] || return
    fi

    header "PCAP Analysis" "Network Packet Capture Analysis"

    local pcap_dir="$OUTDIR/pcap_extracted"
    mkdir -p "$pcap_dir"

    # HTTP objects
    local http_dir="$pcap_dir/http"
    mkdir -p "$http_dir"
    tshark -r "$f" --export-objects "http,$http_dir" 2>/dev/null
    for obj in "$http_dir"/*; do
        [ -f "$obj" ] || continue
        info "HTTP object: $(basename "$obj") ($(stat -c%s "$obj" 2>/dev/null) bytes)"
        emit "pcap_object" "HTTP: $obj"
        run_workflow "$obj"
    done

    # Payload strings — capture to variable first to avoid pipe subshell
    local payloads=$(tshark -r "$f" -T fields -e data.text 2>/dev/null | tr -d '\0')
    while IFS= read -r line; do
        [ -z "$line" ] && continue
        for p in "${FLAG_PATTERNS[@]}"; do
            local match=$(echo "$line" | grep -oP "$p" 2>/dev/null)
            [ -n "$match" ] && emit "flag" "$match"
        done
    done < <(echo "$payloads")

    # DNS queries — check for hex/encoded flags in domain names
    while IFS= read -r domain; do
        [ -z "$domain" ] && continue
        local hex=$(echo "$domain" | grep -oE '[0-9a-fA-F]{40,}' 2>/dev/null)
        if [ -n "$hex" ]; then
            local dec=$(echo "$hex" | xxd -r -p 2>/dev/null | tr -d '\0')
            [ -n "$dec" ] && for p in "${FLAG_PATTERNS[@]}"; do
                local match=$(echo "$dec" | grep -oP "$p" 2>/dev/null)
                [ -n "$match" ] && emit "flag" "$match"
            done
        fi
        for p in "${FLAG_PATTERNS[@]}"; do
            local match=$(echo "$domain" | grep -oP "$p" 2>/dev/null)
            [ -n "$match" ] && emit "flag" "$match"
        done
    done < <(tshark -r "$f" -T fields -e dns.qry.name 2>/dev/null)
}
