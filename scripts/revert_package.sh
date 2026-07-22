#!/bin/bash

SECTOR_BYTES=512
CHUNK_SIZE=200704


function suser() {
	true
}

function revert_system() {
	local offset=0
	local name=$1
	local tmp_path="$1_tmp"
	local output_file=$name.ext4

	total=`echo $1.1-of-* | cut -d '-' -f 3 | cut -d '.' -f 1`
	echo "total: $total"

	for i in $(seq 1 $total)
	do
		file_tgz="$name.$i-of-$total.gz"
		if [ -f $file_tgz ];then
			gzip -d $file_tgz
		fi

		file="$name.$i-of-$total"
		size=$(du -b $file | awk '{print $1}')
		echo $size
		dd status=none if=$file of=$output_file bs=$SECTOR_BYTES seek=$offset count=$CHUNK_SIZE
		offset=$(expr $offset + $CHUNK_SIZE)
	done

	if [ -f $tmp_path ];then
		rm -rf $tmp_path
	fi
	mkdir $tmp_path

	REVERT_TMP="$(pwd)/$tmp_path" REVERT_OUT="$(pwd)/$output_file" \
	REVERT_NAME="$name" fakeroot -- bash -c '
		_extract_mcopy() { mcopy -i "$2" -s -n ::/ "$1" 2>/dev/null; }
		fs=$(file -b "$REVERT_OUT")
		echo "  fs: $fs" >&2
		case "$fs" in
			*FAT*)
				_extract_mcopy "$REVERT_TMP" "$REVERT_OUT"
				;;
			*ext[234]*)
				debugfs -R "rdump / $REVERT_TMP" "$REVERT_OUT" 2>/dev/null
				find "$REVERT_TMP" -mindepth 1 \( -type f -o -type d \) -printf "stat /%P\n" \
				| debugfs -f /dev/stdin "$REVERT_OUT" 2>/dev/null | {
					p=""
					while IFS= read -r line; do
						case "$line" in
							"debugfs: stat "*)
								p="${line#"debugfs: stat "}"
								;;
							*"Mode:"*)
								m="${line#*Mode:}"
								m="${m#"${m%%[![:space:]]*}"}"
								m="${m%%[!0-7]*}"
								if [ -n "$m" ] && [ -n "$p" ]; then
									chmod "$m" "$REVERT_TMP/$p" 2>/dev/null
								fi
								;;
						esac
					done
				}
				;;
			*)
				echo "  unrecognized fs, trying mcopy then debugfs" >&2
				_extract_mcopy "$REVERT_TMP" "$REVERT_OUT"
				;;
		esac
		if [ -z "$(ls -A "$REVERT_TMP" 2>/dev/null)" ]; then
			echo "  primary tool empty, trying fallback" >&2
			debugfs -R "rdump / $REVERT_TMP" "$REVERT_OUT" 2>/dev/null
			[ -z "$(ls -A "$REVERT_TMP" 2>/dev/null)" ] && _extract_mcopy "$REVERT_TMP" "$REVERT_OUT"
		fi
		_cnt=$(ls -A "$REVERT_TMP" 2>/dev/null | wc -l)
		echo "  extracted entries: $_cnt" >&2
		if [ "$_cnt" -gt 0 ]; then
			( cd "$REVERT_TMP" && shopt -s nullglob dotglob && tar --numeric-owner -zcf "../$REVERT_NAME.tgz" * )
		else
			echo "  WARNING: $REVERT_OUT extracted nothing, producing empty tgz" >&2
			tar --numeric-owner -zcf "../$REVERT_NAME.tgz" -T /dev/null
		fi
	'
	rm -rf $tmp_path
}

echo "Start"
if [ $# -lt 1   ] ; then
    echo "./revert_package.sh system"
    exit -1
fi
for c in file mcopy debugfs fakeroot dd tar gzip; do
	command -v "$c" >/dev/null 2>&1 || { echo "ERROR: missing command: $c" >&2; exit 1; }
done
suser
for arg in $*
do
  echo "arg: $arg"
  revert_system "$arg"

done
