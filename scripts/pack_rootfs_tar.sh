#!/bin/bash

_clean_rootfs_before_pack() {
    local rootfs="$1"
    local d
    for d in proc sys run tmp var/tmp var/cache/apt/archives; do
        [ -d "${rootfs}/${d}" ] && find "${rootfs}/${d}" -mindepth 1 -delete 2>/dev/null || true
    done
}

_pack_rootfs_tar() {
    local output="$1"
    local rootfs="$2"
    shift 2
    local -a user_excludes=("$@")
    local -a tar_excludes=(--exclude='./dev' --exclude='./proc' --exclude='./sys'
        --exclude='./run' --exclude='./tmp' --exclude='./var/tmp'
        --exclude='./home/linaro' --exclude='./home/admin')
    local e
    if [ "${#user_excludes[@]}" -gt 0 ]; then
        for e in "${user_excludes[@]}"; do
            case "$e" in
                --exclude=*) tar_excludes+=("$e");;
                *) tar_excludes+=("--exclude=$e");;
            esac
        done
    fi

    local tarf ret=0
    tarf=$(mktemp "${TMPDIR:-/tmp}/rootfs.XXXXXX.tar")
    tar --numeric-owner --owner=0 --group=0 -cf "$tarf" "${tar_excludes[@]}" -C "$rootfs" . || ret=$?
    if [ $ret -eq 0 ] && [ -d "$rootfs/home/linaro" ]; then
        tar --numeric-owner --owner=1000 --group=1000 -rf "$tarf" \
            --exclude='./home/linaro/bsp-debs' --exclude='./home/linaro/debs' \
            -C "$rootfs" ./home/linaro || ret=$?
    fi
    if [ $ret -eq 0 ] && [ -d "$rootfs/home/admin" ]; then
        tar --numeric-owner --owner=1001 --group=1001 -rf "$tarf" \
            -C "$rootfs" ./home/admin || ret=$?
    fi
    if [ $ret -eq 0 ]; then
        gzip -f "$tarf"
        mv "${tarf}.gz" "$output" || ret=$?
    fi
    rm -f "$tarf" "${tarf}.gz"
    return $ret
}

_pack_rootfs_rw_tar() {
    local output="$1"
    local rwdir="$2"
    local tarf

    tarf=$(mktemp "${TMPDIR:-/tmp}/rootfs_rw.XXXXXX.tar")
    tar --numeric-owner --owner=0 --group=0 -cf "$tarf" -C "$rwdir" \
        --exclude=./overlay/home/linaro .
    if [ -d "$rwdir/overlay/home/linaro" ]; then
        tar --numeric-owner --owner=1000 --group=1000 -rf "$tarf" -C "$rwdir" \
            ./overlay/home/linaro
    fi
    gzip -f "$tarf"
    mv "${tarf}.gz" "$output"
}
