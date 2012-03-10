#!/bin/bash


# This file is part of the ttylinux software.
# The license which this software falls under is GPLv2 as follows:
#
# Copyright (C) 2008-2012 Douglas Jerome <douglas@ttylinux.org>
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 2 of the License, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, write to the Free Software Foundation, Inc., 59 Temple
# Place, Suite 330, Boston, MA  02111-1307  USA


# *****************************************************************************
#
# PROGRAM DESCRIPTION
#
#	This script builds the ttylinux root file system initrd image.
#
# CHANGE LOG
#
#	18feb12	drj	Rewrite for build process reorganization.
#	12feb11	drj	Kernel module package no longer is a special case.
#	23jan11	drj	Install packages in package order, not "ls" order.
#	23jan11	drj	Removed basefs and devfs special cases; now packages.
#	21jan11	drj	Added "nopackage" type of package.
#	16dec10	drj	Use new kernel module package location.
#	11dec10	drj	Changed for new platform directory structure.
#	23nov10	drj	Added the use of the optional /dev directory.
#	09oct10	drj	Minor simplifications.
#	05mar10	drj	Removed ttylinux.site-config.sh
#	28feb10	drj	Put all pkg-bin/ files into the file system.
#	07oct08	drj	File creation.
#
# *****************************************************************************


# *************************************************************************** #
#                                                                             #
# S U B R O U T I N E S                                                       #
#                                                                             #
# *************************************************************************** #


# *****************************************************************************
#
# *****************************************************************************

# none


# *************************************************************************** #
#                                                                             #
# M A I N   P R O G R A M                                                     #
#                                                                             #
# *************************************************************************** #


# *****************************************************************************
# Set up the shell functions and environment variables.
# *****************************************************************************

source ./ttylinux-config.sh    # target build configuration
source ./scripts/_functions.sh # build support

dist_root_check    || exit 1
dist_config_setup  || exit 1
build_config_setup || exit 1
build_spec_show    || exit 1


# *****************************************************************************
# Create the empty ttylinux file system image.
# *****************************************************************************

trap "rm -rf ${TTYLINUX_IMG_NAME}" EXIT

echo ""
echo "=> Creating ttylinux file system image (${TTYLINUX_RAMDISK_SIZE} MB)... "
rm --force "${TTYLINUX_IMG_NAME}"
dd if=/dev/zero of="${TTYLINUX_IMG_NAME}" bs=1M count=${TTYLINUX_RAMDISK_SIZE}
mke2fs -F -m 0 -q "${TTYLINUX_IMG_NAME}"
echo "...DONE"
echo ""

trap - EXIT

ttylinux_target_mount
ttylinux_target_umount


# *****************************************************************************
# Install pakages into the file system.
# *****************************************************************************

echo ""
echo "##### START installing"

ttylinux_target_mount
trap "ttylinux_target_umount" EXIT

shareDir="${TTYLINUX_MNT_DIR}/usr/share/ttylinux"
pushd "${TTYLINUX_BUILD_DIR}" >/dev/null 2>&1
rm --force TIME_STAMP
>TIME_STAMP

_pkglst=""
_p=""

echo -n "i> Making package list ... "
for _p in $(ls ${TTYLINUX_PKGBIN_DIR}); do
	if [[ x"${_p:0:16}" == x"ttylinux-basefs-" ]]; then
		_pkglst="${_p} ${_pkglst}"
	else
		_pkglst="${_pkglst} ${_p}"
	fi
done
echo "DONE"

echo "i> Installing packages."
for _p in ${_pkglst}; do
	_p=${_p%-${TTYLINUX_CPU}.tbz}
	echo "=> ${_p}"
	cp "${TTYLINUX_PKGBIN_DIR}/${_p}-${TTYLINUX_CPU}.tbz" "${_p}.tar.bz2"
	bunzip2 --force "${_p}.tar.bz2"
	tar --extract --file="${_p}.tar" --directory=${TTYLINUX_MNT_DIR}
	if [[ x"${_p#*-}" != x"nopackage" ]]; then
		tar --list --file="${_p}.tar" >"${shareDir}/pkg-${_p}-FILES"
	fi
	rm --force "${_p}.tar"
done;
unset _pkglst
unset _p

echo -n "i> Updating birthdays ... "
find "${TTYLINUX_MNT_DIR}" -type d -o -type f \
	-exec touch --reference=${TTYLINUX_BUILD_DIR}/TIME_STAMP {} \;
echo "DONE"

rm --force TIME_STAMP
popd >/dev/null 2>&1
unset shareDir

>${TTYLINUX_MNT_DIR}/etc/.norootfsck

echo "File system usage [file system size=${TTYLINUX_RAMDISK_SIZE}MB]:"
du -sh ${TTYLINUX_MNT_DIR}

trap - EXIT
ttylinux_target_umount

tune2fs -C 0 -c 3 "${TTYLINUX_IMG_NAME}"
ls -hl ${TTYLINUX_IMG_NAME} | sed --expression="s|$(pwd)/||"
echo "i> File system image file $(basename ${TTYLINUX_IMG_NAME}) is ready."

# Make a CPIO archive to use for an initramfs
#
#echo ""
#ttylinux_target_mount
#trap "ttylinux_target_umount" EXIT
#pushd ${TTYLINUX_MNT_DIR}
#rm --force "${TTYLINUX_IRD_NAME}"
#find . | cpio \
#		--create \
#		--format=newc \
#		--no-absolute-filenames >${TTYLINUX_IRD_NAME}
#popd
#trap - EXIT
#ttylinux_target_umount
#ls -hl ${TTYLINUX_IRD_NAME} | sed --expression="s|$(pwd)/||"
#echo "i> File system CPIO archive $(basename ${TTYLINUX_IRD_NAME}) is ready."

echo "##### DONE installing"
echo ""


# *****************************************************************************
# Exit OK
# *****************************************************************************

exit 0


# end of file
