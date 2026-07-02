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
    local -a tar_excludes=(--exclude='dev' --exclude='proc' --exclude='sys'
        --exclude='run' --exclude='tmp' --exclude='var/tmp')
    if [ "${#user_excludes[@]}" -gt 0 ]; then
        tar_excludes+=("${user_excludes[@]}")
    fi

    local -a deb_list=()
    local d f tmp_sophgo_deb="" sophgo_fs ret=0
    for d in "${BSP_DEBS}" "${SDK_DEBS}" "${MOD_DEBS}" \
             "${TOP_DIR}/ubuntu/bootloader-arm64/distro/debs"; do
        [ -d "$d" ] || continue
        shopt -s nullglob
        for f in "$d"/*.deb; do
            deb_list+=("$f")
        done
        shopt -u nullglob
    done
    sophgo_fs="${DISTRO_OVERLAY_DIR}/${CVIARCH}/sophgo-fs"
    if [ -f "${sophgo_fs}/DEBIAN/control" ]; then
        tmp_sophgo_deb=$(mktemp "${TMPDIR:-/tmp}/sophgo-fs.XXXXXX.deb")
        if dpkg-deb -b "$sophgo_fs" "$tmp_sophgo_deb" >/dev/null 2>&1; then
            deb_list+=("$tmp_sophgo_deb")
        else
            rm -f "$tmp_sophgo_deb"
            tmp_sophgo_deb=""
        fi
    fi

    fakeroot bash "${TOP_DIR}/build/scripts/pack_rootfs_tar.sh" \
        "$output" "$rootfs" "${tar_excludes[@]}" -- "${deb_list[@]}" || ret=$?
    rm -f "$tmp_sophgo_deb"
    return $ret
}

_pack_rootfs_tar_run() {
    set -euo pipefail

    local output="$1" rootfs="$2"
    shift 2

    local excludes=()
    local debs=()
    while [ $# -gt 0 ]; do
        case "$1" in
            --exclude=*) excludes+=("$1"); shift;;
            --) shift; while [ $# -gt 0 ]; do debs+=("$1"); shift; done; break;;
            *) debs+=("$1"); shift;;
        esac
    done

    apply_deb_ownership() {
        local rootfs="$1"
        shift
        local deb perm ug path uid gid
        for deb in "$@"; do
            [ -f "$deb" ] || continue
            while read -r perm ug _ _ _ path; do
                path="${path#./}"
                path="${path%% ->*}"
                [ -n "$path" ] || continue
                [ -e "$rootfs/$path" ] || [ -L "$rootfs/$path" ] || continue
                uid="${ug%/*}"; gid="${ug#*/}"
                chown "$uid:$gid" "$rootfs/$path" 2>/dev/null || true
            done < <(dpkg-deb --fsys-tarfile "$deb" 2>/dev/null | tar --numeric-owner -tvf - 2>/dev/null)
        done
    }

    chown -R 0:0 "$rootfs"
    [ "${#debs[@]}" -gt 0 ] && apply_deb_ownership "$rootfs" "${debs[@]}"
    [ -d "$rootfs/home/linaro" ] && chown -R 1000:1000 "$rootfs/home/linaro"
    [ -d "$rootfs/data" ] && chown -R 1000:1000 "$rootfs/data"

    local tar_args=(--numeric-owner -zcf "$output"
        --exclude=dev --exclude=proc --exclude=sys
        --exclude=run --exclude=tmp --exclude=var/tmp)
    [ "${#excludes[@]}" -gt 0 ] && tar_args+=("${excludes[@]}")
    tar_args+=(-C "$rootfs" .)
    tar "${tar_args[@]}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    _pack_rootfs_tar_run "$@"
fi
