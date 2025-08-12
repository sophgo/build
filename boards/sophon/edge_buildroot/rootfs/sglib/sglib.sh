#!/bin/bash

REPO=$1
FILE=$2
DLDIR=$3
BUILDIR=$4
BOARDDIR=$5

function copy_sophon_media_buildroot()
{
	local DL_FILE=$(ls ${DLDIR}/$(basename ${FILE}) 2>/dev/null)
	local SOPHON_MEDIA_PACK_PATH=$BUILDIR/$(basename ${DL_FILE} .tar.gz)
	local BUILDROOT_INSTALL_PATH=$BOARDDIR

	tar -xf ${DL_FILE} -C $BUILDIR

	find "$SOPHON_MEDIA_PACK_PATH" -maxdepth 1 -type d -name "sophon*" | while read -r sophon_pkg; do
		src_opt="${sophon_pkg}/opt"
		if [ -d "$src_opt" ]; then
			rsync -av --ignore-existing "${src_opt}/" "${BUILDROOT_INSTALL_PATH}/"
		fi
	done
	pushd ${BUILDROOT_INSTALL_PATH}/sophon
	local TARGET_PROFILE_D_DIR="${BUILDROOT_INSTALL_PATH}/../etc/profile.d"
	local PROFILE_SCRIPT="${TARGET_PROFILE_D_DIR}/sophon-media-libs.sh"
	mkdir -p "$TARGET_PROFILE_D_DIR"
	touch "$PROFILE_SCRIPT"
	sh -c "> '$PROFILE_SCRIPT'"

	mkdir -p "$TARGET_PROFILE_D_DIR"
	for dir in sophon-*_*; do
		if [[ -d "$dir" ]]; then
			prefix="${dir%_*}"
			version="${dir#*_}"
			latest_dir=$(ls -dv ${prefix}_* | sort -Vr | head -n 1)
			ln -sfn "/opt/sophon/$latest_dir" "${prefix}-latest"
			if [[ -d "$dir/lib" && -d "$dir/data" ]]; then
				if find "$dir/data" -maxdepth 1 -type f -name '*.conf' | grep -q .; then
					echo "export LD_LIBRARY_PATH=/opt/sophon/${prefix}-latest/lib:\$LD_LIBRARY_PATH" >> "$PROFILE_SCRIPT"
				fi
				find "$dir/data" -maxdepth 1 -type f -name '*.sh' -print0 | while IFS= read -r -d '' sh_file; do
					cp -v "$sh_file" "$TARGET_PROFILE_D_DIR"
					chmod 644 "$TARGET_PROFILE_D_DIR/$(basename "$sh_file")"
				done
			fi
		fi
	done
	chmod 644 "$PROFILE_SCRIPT"
	popd
}

function copy_isp_lib_buildroot()
{
	local DL_FILE=$(ls ${DLDIR}/$(basename ${FILE}) 2>/dev/null)
	local ISP_PACK_PATH=$BUILDIR/$(basename ${DL_FILE} .tar.gz)/opt/sophon
	local BUILDROOT_INSTALL_PATH=$BOARDDIR/sophon
	local src_opt="${ISP_PACK_PATH}"

	tar -xf ${DL_FILE} -C $BUILDIR

	if [[ -d "$src_opt" ]]; then
		mkdir -p $BUILDROOT_INSTALL_PATH
		rsync -av --ignore-existing "${src_opt}/" "${BUILDROOT_INSTALL_PATH}/"
	fi
	pushd "${BUILDROOT_INSTALL_PATH}" || return 1
	local TARGET_PROFILE_D_DIR="${BUILDROOT_INSTALL_PATH}/../../etc/profile.d"
	local PROFILE_SCRIPT="${TARGET_PROFILE_D_DIR}/libisp-libs.sh"
	mkdir -p "$TARGET_PROFILE_D_DIR"
	touch "$PROFILE_SCRIPT"
	sh -c "> '$PROFILE_SCRIPT'"
	local latest_ver=$(find . -maxdepth 1 -type d -regex ".*/libsophon-[0-9]+\.[0-9]+\.[0-9]+" -printf "%f\n" \
		| sort -t '.' -k1,1nr -k2,2nr -k3,3nr   | head -n1
	)
		echo "export LD_LIBRARY_PATH=/opt/sophon/sophon-soc-libisp_1.0.0/lib:\$LD_LIBRARY_PATH" >> "$PROFILE_SCRIPT"
		find "${latest_ver}/data/" -maxdepth 1 -name "*.sh" -print0 | \
			while IFS= read -r -d $'\0' file; do
				cp -v "$file" "$TARGET_PROFILE_D_DIR"
				chmod 644 "${TARGET_PROFILE_D_DIR}/$(basename "$file")"
			done
	[[ -f "$PROFILE_SCRIPT" ]] && chmod 644 "$PROFILE_SCRIPT"
	popd || return 1
}

function copy_libsophon_buildroot()
{
	local DL_FILE=$(ls ${DLDIR}/$(basename ${FILE}) 2>/dev/null)
	local LIBSOPHON_PACK_PATH=$BUILDIR/$(basename ${DL_FILE} .tar.gz)/opt/sophon
	local BUILDROOT_INSTALL_PATH=$BOARDDIR/sophon
	local src_opt="${LIBSOPHON_PACK_PATH}/"

	tar -xf ${DL_FILE} -C $BUILDIR

	if [[ -d "$src_opt" ]]; then
	mkdir -p $BUILDROOT_INSTALL_PATH
		rsync -av --ignore-existing "${src_opt}/" "${BUILDROOT_INSTALL_PATH}/"
	fi
	pushd "${BUILDROOT_INSTALL_PATH}" || return 1
	local TARGET_PROFILE_D_DIR="${BUILDROOT_INSTALL_PATH}/../../etc/profile.d"
	local PROFILE_SCRIPT="${TARGET_PROFILE_D_DIR}/libsophon-libs.sh"
	mkdir -p "$TARGET_PROFILE_D_DIR"
	touch "$PROFILE_SCRIPT"
	sh -c "> '$PROFILE_SCRIPT'"
	local latest_ver=$(find . -maxdepth 1 -type d -regex ".*/libsophon-[0-9]+\.[0-9]+\.[0-9]+" -printf "%f\n" \
		| sort -t '.' -k1,1nr -k2,2nr -k3,3nr   | head -n1
	)
		ln -sfn "/opt/sophon/$latest_ver" "libsophon-current"
		echo "export LD_LIBRARY_PATH=/opt/sophon/libsophon-current/lib:\$LD_LIBRARY_PATH" >> "$PROFILE_SCRIPT"
		find "${latest_ver}/data/" -maxdepth 1 -name "*.sh" -print0 | \
			while IFS= read -r -d $'\0' file; do
				cp -v "$file" "$TARGET_PROFILE_D_DIR"
				chmod 644 "${TARGET_PROFILE_D_DIR}/$(basename "$file")"
			done
	[[ -f "$PROFILE_SCRIPT" ]] && chmod 644 "$PROFILE_SCRIPT"

	find $BOARDDIR/sophon/$latest_ver/data/ -name bm1688_firmware* -exec ln -snrf {} $BOARDDIR/../lib/firmware/ \;

	popd || return 1
}

case "$REPO" in
	"sophon_media_test")
		copy_sophon_media_buildroot
		;;
	"isp_test")
		copy_isp_lib_buildroot
		;;
	"libsophon_test")
		copy_libsophon_buildroot
		;;
	*)
		;;
esac