#!/bin/bash


# Inherited Variables:
#
# TTYLINUX_XTOOL_DIR = ${TTYLINUX_XBT_DIR}/${TTYLINUX_XBT}
# TTYLINUX_PLATFORM


# *****************************************************************************
# Check Command Line Arguments
# *****************************************************************************

if [[ $# -ne 3 ]]; then
	echo "$(basename $0) called with wrong number of arguments ($#)."
	echo "=> Three arguments are needed."
	exit 1
fi
ubootVersion=$1
ubootPatch=$2
ubootTarget=$3
echo ""
echo "=> Making u-boot-${ubootVersion} patch ${ubootPatch} for ${ubootTarget}"


# *****************************************************************************
# Remove any left-over previous build things.  Then untar U-Boot source package.
# *****************************************************************************

echo "=> Removing old build products, if any, and untarring ${ubootVersion} ..."
rm -rf MLO mlo u-boot.bin mkimage
rm -rf u-boot-${ubootVersion}
tar -xf u-boot-${ubootVersion}.tar.bz2


# *****************************************************************************
# Build U-Boot
# *****************************************************************************

cd u-boot-${ubootVersion}

oldPath=${PATH}
export PATH="${TTYLINUX_XTOOL_DIR}/host/usr/bin:${PATH}"

if [[ x"${ubootPatch}" != x"none" ]]; then
	_patchFile="p-${ubootVersion}-${TTYLINUX_PLATFORM}-${ubootPatch}.patch"
	echo "=> Patching with ${_patchFile}"
	patch -p1 <../patch/${_patchFile} 
	unset _patchFile
fi

if [[ x"${ubootTarget}" = x"mkimage" ]]; then
	# Make the host tools.
	rm -f ../${ubootTarget}.MAKELOG
	make tools >../${ubootTarget}.MAKELOG 2>&1
	#
	# Get the mkimage program.
	cp tools/mkimage ..
else
	# Make the "u-boot.bin" and its host tools.
	rm -f ../${ubootTarget}.MAKELOG
	CROSS_COMPILE=${TTYLINUX_XBT}- ./MAKEALL ${ubootTarget} | grep -v "^$"
	cp LOG/${ubootTarget}.MAKELOG ..
	#
	# Get the programs.
	[[ -f MLO           ]] && cp MLO ..
	[[ -f u-boot.bin    ]] && cp u-boot.bin ..
	[[ -f tools/mkimage ]] && cp tools/mkimage ..
fi

export PATH=${oldPath}

cd ..

_list=""
[[ -f MLO        ]] && _list="${_list} MLO"
[[ -f u-boot.bin ]] && _list="${_list} u-boot.bin"
[[ -f mkimage    ]] && _list="${_list} mkimage"
echo ""
echo "=> New files:"
ls --color -lh ${_list} || true
unset _list


# *****************************************************************************
# Cleanup
# *****************************************************************************

rm -rf "u-boot-${ubootVersion}"

unset CROSS_COMPILE
unset oldPath
unset ubootVersion
unset ubootPatch
unset ubootTarget


# *****************************************************************************
# Exit OK
# *****************************************************************************

exit 0
