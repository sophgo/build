#!/bin/bash

download_and_verify_file() {
    local file_url="$1"
    local file_path="$2"
    local expected_md5="$3"
    local download_tool="$4"

    echo "Processing file: $(basename "$file_path")"

    python3 -m pip install dfss --upgrade
    if [ ! -e "$file_path" ]; then
        echo "Downloading file..."
        case $download_tool in
            "wget")
                wget -q --show-progress "$file_url" -O "$file_path"
                ;;
            "dfss")
                python -m dfss --url="$file_url"
                local filename=$(basename "$file_url")
                if [ -f "$filename" ]; then
                    mv "$filename" "$file_path"
                fi
                ;;
            *)
                echo "Unsupported download tool: $download_tool"
                return 1
                ;;
        esac
    else
        local current_md5=$(md5sum "$file_path" | awk '{print $1}')
        if [ "$current_md5" != "$expected_md5" ]; then
            echo "File exists but MD5 mismatch, re-downloading..."
            rm -f "$file_path"
            case $download_tool in
                "wget") wget -q --show-progress "$file_url" -O "$file_path" ;;
                "dfss")
                    python -m dfss --url="$file_url"
                    local filename=$(basename "$file_url")
                    [ -f "$filename" ] && mv "$filename" "$file_path"
                    ;;
            esac
        else
            echo "File exists and MD5 matches, skipping download."
        fi
    fi

    local final_md5=$(md5sum "$file_path" | awk '{print $1}')
    if [ "$final_md5" != "$expected_md5" ]; then
        echo "Error: File $(basename "$file_path") MD5 verification failed after download."
        echo "Expected MD5: $expected_md5"
        echo "Actual MD5: $final_md5"
        return 1
    fi

    echo "File verification successful."
    return 0
}

clean_distro() {
    if [ -d "${TOP_DIR}/ubuntu/distro" ]; then
        find "${TOP_DIR}/ubuntu/distro" \
            -name "distro_*.tgz" -delete
    fi
}

setup_debian_env() {
    SUPPORTED_DISTROS=("jammy" "focal" "debian" "bookworm")
    DISTRO=${BUILD_ROOTFS_NAME:-jammy}
    SUPPORTED=0
    for d in "${SUPPORTED_DISTROS[@]}"; do
        if [ "$d" = "$DISTRO" ]; then
            SUPPORTED=1
            break
        fi
    done

    if [ $SUPPORTED -eq 0 ]; then
        echo "warning:not support DISTRO: '$DISTRO',use default 'jammy'"
        export DISTRO="jammy"
    fi
    export ROOT_TOP_DIR="$TOP_DIR"/ubuntu
    export ROOT_OUT_DIR=${ROOT_TOP_DIR}/install/soc_${CVIARCH}
    export EDGE_ROOTFS_DIR=${ROOT_TOP_DIR}/install/soc_${CVIARCH}/rootfs
    export DISTRO_OVERLAY_DIR="${TOP_DIR}"/ubuntu/bootloader-arm64/distro/overlay

    if [ "$DISTRO" = "debian" ] || [ "$DISTRO" = "bookworm" ]; then
        export DISTRO_MD5="f506f82aeb01215568f9b0c1afb0cbe1"
        export DISTRO_URL="open@sophgo.com:/gemini-sdk/rootfs/bookworm_${DISTRO_MD5}.tgz"
        export FETCH_CMD="dfss"
    else
        case "$DISTRO" in
            "focal")
                export DISTRO_MD5="f93ebbaa47adb3231aef80661e9d01bf"
                ;;
            "jammy")
                export DISTRO_MD5="c6d415287309d0f61f05186621e5bb58"
                ;;
        esac
        export DISTRO_URL="open@sophgo.com:/gemini-sdk/rootfs/distro_${DISTRO}_${DISTRO_MD5}.tgz"
        export FETCH_CMD="dfss"
    fi

    export BSP_DEBS=${ROOT_OUT_DIR}/bsp-debs
    export SDK_DEBS=${ROOT_OUT_DIR}/sdk-debs
    export MOD_DEBS=${ROOT_OUT_DIR}/mod-debs
}

fetch_debian_based_rootfs() {
    local staging="${EDGE_ROOTFS_DIR}.staging.$$"
    local old_rootfs="${EDGE_ROOTFS_DIR}.old.$$"

    rm -rf "$staging"
    mkdir -p "$staging"

    if [ "$DISTRO" = "debian" ] || [ "$DISTRO" = "bookworm" ]; then
        local download_dir="${TOP_DIR}/ubuntu/bookworm"
        local file_path="${download_dir}/bookworm.tgz"
        mkdir -p "$download_dir"
        cd "$download_dir"

        download_and_verify_file "$DISTRO_URL" "$file_path" "$DISTRO_MD5" "$FETCH_CMD" || return 1
        _extract_rootfs_tar "$file_path" "$staging" || return 1
    else
        local download_dir="${TOP_DIR}/ubuntu/distro"
        local file_path="${download_dir}/distro_${DISTRO}.tgz"
        mkdir -p "$download_dir"

        download_and_verify_file "$DISTRO_URL" "$file_path" "$DISTRO_MD5" "$FETCH_CMD" || return 1
        _extract_rootfs_tar "$file_path" "$staging" || return 1
    fi

    if [ -d "${EDGE_ROOTFS_DIR}" ]; then
        rm -rf "$old_rootfs"
        mv "${EDGE_ROOTFS_DIR}" "$old_rootfs" 2>/dev/null || {
            echo "Error: cannot replace existing rootfs at ${EDGE_ROOTFS_DIR}" >&2
            rm -rf "$staging"
            return 1
        }
        rm -rf "$old_rootfs" 2>/dev/null || echo "warning: leftover ${old_rootfs} contains root-owned files from a prior privileged build; remove it manually when possible"
    fi
    mv "$staging" "${EDGE_ROOTFS_DIR}"
}

build_debian_based_rootfs() {
    setup_debian_env || return $?
    fetch_debian_based_rootfs || return $?
    pack_edge_rootfs || return $?
}

_extract_rootfs_tar() {
    local archive="$1" dest="$2"
    zcat "$archive" | tar -p --no-same-owner --exclude='dev' -C "$dest" -xf -
    mkdir -p "$dest/dev"
    if [ ! -x "$dest/bin/bash" ] && [ ! -x "$dest/usr/bin/bash" ]; then
        echo "Error: rootfs extraction failed, bash not found under ${dest}" >&2
        return 1
    fi
}

_rootfs_run() {
    local rootfs="$1"; shift
    PROOT_NO_SECCOMP="${PROOT_NO_SECCOMP:-1}" \
        proot -q qemu-aarch64-static -0 -r "$rootfs" \
            -b /dev:/dev -b /proc:/proc -b /sys:/sys -w / "$@"
}

_fix_maintainer_scripts() {
    local rootfs="$1" f first
    find "$rootfs/var/lib/dpkg/info" -type f \
        \( -name '*.postinst' -o -name '*.preinst' -o -name '*.prerm' \
           -o -name '*.postrm' -o -name '*.config' \) 2>/dev/null | while read -r f; do
        first=$(head -1 "$f" 2>/dev/null || true)
        case "$first" in '#!'*) ;; *) sed -i '1i#!/bin/sh' "$f" ;; esac
        chmod +x "$f"
    done
}

pack_edge_rootfs() {
    (
        set -euo pipefail
        trap 'echo "pack_edge_rootfs: FAIL at line $LINENO: $BASH_COMMAND" >&2' ERR

        : "${TOP_DIR:?TOP_DIR not set; source envsetup_soc.sh && defconfig first}"
        : "${EDGE_ROOTFS_DIR:?EDGE_ROOTFS_DIR not set}"
        : "${BSP_DEBS:?}" : "${SDK_DEBS:?}" : "${MOD_DEBS:?}"
        : "${DISTRO_OVERLAY_DIR:?}" : "${CVIARCH:?}"
        : "${KERNEL_SRC:?}" : "${SIDE_TYPE:?}"
        : "${COMMON_TOOLS_PATH:?}" : "${FLASH_PARTITION_XML:?}"
        MW_VER="${MW_VER:-}"
        CHIP_ARCH="${CHIP_ARCH:-}"

        local c
        for c in proot qemu-aarch64-static dpkg-deb python3; do
            command -v "$c" >/dev/null 2>&1 || { echo "ERROR: missing command: $c" >&2; exit 1; }
        done
        if ! PROOT_NO_SECCOMP="${PROOT_NO_SECCOMP:-1}" proot --help >/dev/null 2>&1; then
            echo "ERROR: proot cannot run (ptrace blocked? in Docker add --security-opt seccomp=unconfined --cap-add=SYS_PTRACE)" >&2
            exit 1
        fi

        echo "pack_edge_rootfs: building rootfs at $EDGE_ROOTFS_DIR"

        mkdir -p "${EDGE_ROOTFS_DIR}/home/linaro/debs"
        local sf="${DISTRO_OVERLAY_DIR}/${CVIARCH}/sophgo-fs"
        if [ -f "${sf}/DEBIAN/control" ]; then
            local version
            version=$(grep Version "${sf}/DEBIAN/control" | cut -d' ' -f2)
            dpkg-deb -b "${sf}" "${EDGE_ROOTFS_DIR}/home/linaro/debs/sophgo-bsp-rootfs_${version}_arm64.deb"
        else
            echo "WARN: ${sf}/DEBIAN/control missing; sophgo-bsp-rootfs deb not built" >&2
        fi

        mkdir -p "${BSP_DEBS}" "${SDK_DEBS}" "${MOD_DEBS}"
        rm -rf "${BSP_DEBS}"/linux*.deb
        rm -rf "${SDK_DEBS}"/linux-image*.deb

        local OPENCLAW_SRC="${TOP_DIR}/build/tools/cv186x/openclaw-src"
        if [ -d "$OPENCLAW_SRC" ] && [ -f "$OPENCLAW_SRC/DEBIAN/control" ]; then
            echo "Packaging openclaw..."
            local DATA_DIR_INSIDE_SRC="${OPENCLAW_SRC}/data"
            local TEMP_DATA_DIR_OUTSIDE_SRC="${TOP_DIR}/build/tools/cv186x/openclaw-data-temp"
            if [ -d "$DATA_DIR_INSIDE_SRC" ]; then
                mv "$DATA_DIR_INSIDE_SRC" "$TEMP_DATA_DIR_OUTSIDE_SRC"
                echo "Moved data directory out for deb packaging"
            fi
            dpkg-deb --build "$OPENCLAW_SRC" "${MOD_DEBS}/openclaw.deb"
            echo "openclaw.deb built and copied to ${MOD_DEBS}"
            [ -d "$TEMP_DATA_DIR_OUTSIDE_SRC" ] && mv "$TEMP_DATA_DIR_OUTSIDE_SRC" "$DATA_DIR_INSIDE_SRC" && echo "Restored data directory"
            echo "--- Openclaw packaging finished ---"
        fi

        shopt -s nullglob
        case "$KERNEL_SRC" in
            linux-common) update_files_if_newer "linux*.deb" "${TOP_DIR}/linux-common/build" "${BSP_DEBS}" || true;;
            linux_5.10)   update_files_if_newer "linux*.deb" "${TOP_DIR}/linux_5.10/build"   "${BSP_DEBS}" || true;;
            *) echo "error, KERNEL_SRC should be 'linux-common' or 'linux_5.10'." >&2;;
        esac
        case "$SIDE_TYPE" in
            device)
                update_files_if_newer "middleware_*.deb" "${TOP_DIR}/middleware/${MW_VER}" "${SDK_DEBS}" || true
                update_files_if_newer "tdlsdk_*.deb" "${TOP_DIR}/tdl_sdk/install/${CHIP_ARCH}" "${SDK_DEBS}" || true
                ;;
            edge)
                update_files_if_newer "sophon-media-soc-sophon-{ffmpeg,opencv,gstreamer,sample}_*_arm64.deb" "${TOP_DIR}/sophon_media/buildit" "${SDK_DEBS}" || true
                update_files_if_newer "sophon-soc-libisp*arm64.deb" "${TOP_DIR}/middleware/v2/modules/isp/cv186x/v4l2_adapter" "${SDK_DEBS}" || true
                ;;
            *) echo "error, SIDE_TYPE should be 'device' or 'edge'." >&2;;
        esac
        update_files_if_newer "sophon-soc-libsophon*.deb" "${TOP_DIR}/libsophon/build" "${SDK_DEBS}" || true
        shopt -u nullglob

        echo "copy overlay file to rootfs..."
        cp -rf "$DISTRO_OVERLAY_DIR"/common/rootfs/* "$DISTRO_OVERLAY_DIR"/"$CVIARCH"/rootfs/* "${EDGE_ROOTFS_DIR}" 2>/dev/null || true
        python "$COMMON_TOOLS_PATH/image_tool/mkcvipart_edge.py" "$FLASH_PARTITION_XML" "${EDGE_ROOTFS_DIR}/etc/" --fw_env
        find "${TOP_DIR}/ubuntu/bootloader-arm64/distro/debs" -name '*.deb' -exec cp -f {} "${MOD_DEBS}" \; 2>/dev/null || true

        mkdir -p "${EDGE_ROOTFS_DIR}/home/linaro/bsp-debs"
        find "${BSP_DEBS}" -maxdepth 1 -type f -exec cp -f {} "${EDGE_ROOTFS_DIR}/home/linaro/bsp-debs" \;
        find "${SDK_DEBS}" -maxdepth 1 -type f -exec cp -f {} "${EDGE_ROOTFS_DIR}/home/linaro/debs" \;
        find "${MOD_DEBS}" -maxdepth 1 -type f -exec cp -f {} "${EDGE_ROOTFS_DIR}/home/linaro/debs" \;

        echo "install packages (dpkg unpack)..."
        _rootfs_run "${EDGE_ROOTFS_DIR}" /bin/bash <<'EOT'
export LC_ALL=C
export DEBIAN_FRONTEND=noninteractive
echo -e "LC_ALL=C.UTF-8\n" > /etc/default/locale
echo "Defaults timestamp_timeout=43200" | tee -a /etc/sudoers
for deb_dir in /debs /home/linaro/debs; do
    if [ -d "${deb_dir}" ] && ls "${deb_dir}"/*.deb >/dev/null 2>&1; then
        dpkg --unpack "${deb_dir}"/*.deb
    fi
done
EOT

        _fix_maintainer_scripts "${EDGE_ROOTFS_DIR}" || true

        echo "configure packages (dpkg configure)..."
        _rootfs_run "${EDGE_ROOTFS_DIR}" /bin/bash <<'EOT'
export LC_ALL=C
export DEBIAN_FRONTEND=noninteractive
dpkg --configure -a
for deb_dir in /debs /home/linaro/debs; do
    for file in "${deb_dir}"/*; do
        file=$(basename "${file}")
        if [ "${file##*.}" = "whl" ]; then
            pip3 install --no-index --find-links=file://"${deb_dir}" "${file%%-*}"
        fi
    done
    rm -rf "${deb_dir}"
done
systemctl disable apt-daily.timer apt-daily-upgrade.timer
systemctl disable apt-daily.service apt-daily-upgrade.service unattended-upgrades.service
systemctl mask     unattended-upgrades.service apt-daily.service apt-daily-upgrade.service
EOT

        if [ "$(id -u)" = "0" ]; then
            chown 1000:1000 -R "${EDGE_ROOTFS_DIR}/data" 2>/dev/null || true
        fi

        echo "pack_edge_rootfs: done"
    )
}
