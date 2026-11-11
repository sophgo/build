#!/bin/bash
#
# For alios
#

function _build_alios_env()
{
	export ALIOS_PATH FLASH_PARTITION_XML

	cd "$ALIOS_PATH" || return
	if [ ! -f ".yoc" ]; then
		yoc init;
	fi;
}

function clean_alios()
{(
	print_notice "Run ${FUNCNAME[0]}() function"
	_build_alios_env

	cd "$BUILD_PATH" || return
	make alios_clean || return "$?"
)}

function build_alios()
{(
	print_notice "Run ${FUNCNAME[0]}() function"
	_build_alios_env

	cd "$BUILD_PATH" || return
	make alios || return "$?"
)}
