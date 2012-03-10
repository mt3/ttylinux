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
isolinuxVersion=$1
isolinuxPatch=$2
isolinuxTarget=$3
echo ""
echo "=> Making isolinux"
echo "   version ... ${isolinuxVersion}"
echo "   patch ..... ${isolinuxPatch}"
echo "   for ....... ${isolinuxTarget}"


# *****************************************************************************
# Remove any left-over previous build things.  Then untar U-Boot source package.
# *****************************************************************************

echo "=> Removing old build products, if any, and untarring ..."
rm -rf isolinux.bin syslinux
rm -rf syslinux-${isolinuxVersion}
tar -xf syslinux-${isolinuxVersion}.tar.bz2


# *****************************************************************************
# Build syslinux
# *****************************************************************************

cp "syslinux-${isolinuxVersion}/core/isolinux.bin" isolinux.bin
cp "syslinux-${isolinuxVersion}/linux/syslinux"    syslinux

echo "=> New files:"
ls --color -lh isolinux.bin || true
ls --color -lh syslinux     || true


# *****************************************************************************
# Cleanup
# *****************************************************************************

rm -rf "syslinux-${isolinuxVersion}"

unset isolinuxVersion
unset isolinuxPatch
unset isolinuxTarget


# *****************************************************************************
# Exit OK
# *****************************************************************************

exit 0
