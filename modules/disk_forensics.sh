MD_NAME="Disk Forensics"
MD_DESC="Analyze disk images (DD/IMG/ISO): partitions, file systems, file carving"
MD_TYPES="data"
MD_DEPS="mmls fls icat"
MD_PRIORITY=52
MD_PRODUCES="disk_partition disk_file flag"

analyze_disk_forensics() {
    local f="$1"
    local ftype=$(file -b "$f")

    if ! echo "$ftype" | grep -qiE "DOS/MBR boot sector|ISO 9660|filesystem|ext[234]|NTFS|FAT|x86 boot"; then
        return
    fi

    header "Disk Forensics" "Disk Image Analysis"
    info "Disk image detected: $ftype"

    local disk_dir="$OUTDIR/disk_carved"
    mkdir -p "$disk_dir"

    # List partitions
    mmls "$f" 2>/dev/null > "$disk_dir/partitions.txt"
    if [ -s "$disk_dir/partitions.txt" ]; then
        emit "disk_partition" "Partition table: $disk_dir/partitions.txt"
    fi

    # Try to find the first data partition and extract files
    while read offset; do
        [ -z "$offset" ] && continue
        info "Exploring partition at offset $offset"
        fls -o "$offset" -r "$f" 2>/dev/null > "$disk_dir/fls_offset_${offset}.txt"
        while read inode name; do
            [ -z "$inode" ] && continue
            local lname=$(basename "$name" 2>/dev/null)
            icat -o "$offset" "$f" "$inode" > "$disk_dir/$lname" 2>/dev/null
            if [ -f "$disk_dir/$lname" ] && [ -s "$disk_dir/$lname" ]; then
                info "Extracted: $lname (inode $inode)"
                emit "disk_file" "Carved: $disk_dir/$lname"
                emit "carved" "Extracted: $disk_dir/$lname"
                run_workflow "$disk_dir/$lname"
            fi
        done < <(grep -iE 'flag|secret|key|password|\.txt$|\.jpg$|\.png$' "$disk_dir/fls_offset_${offset}.txt" 2>/dev/null | awk '{print $3, $NF}')
    done < <(mmls "$f" 2>/dev/null | grep -E "Linux|NTFS|FAT" | awk '{print $4}')
}
