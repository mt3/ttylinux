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
#	This script initializes the ttylinux build process.
#
# CHANGE LOG
#
#	15feb12	drj	Rewrite for build process reorganization.
#	29jan12	drj	Changed platform boot.cfg to platform bootloader.cfg.
#	15mar11	drj	Added platform boot.cfg support.
#	23jan11	drj	Removed basefs and devfs; these now are packages.
#	08jan11	drj	Added the collecting of glibc i18n data.
#	15dec10	drj	Use new dev node package file name and location.
#	11dec10	drj	Changed for the new platform directory structure.
#	20nov10	drj	Added the separate /dev directory.
#	03mar10	drj	Removed ttylinux.site-config.sh
#	07oct08	drj	File creation.
#
# *****************************************************************************


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

dist_root_check   || exit 1
dist_config_setup || exit 1


# *****************************************************************************
# Set up the directory tree used for building ttylinux packages.
# *****************************************************************************

trap "rm --force --recursive ${TTYLINUX_BUILD_DIR}/*" EXIT

echo -n "=> Creating preliminary development build directories ... "
rm --force --recursive "${TTYLINUX_BUILD_DIR}/"*
mkdir --mode=755 "${TTYLINUX_BUILD_DIR}/kpkgs"
mkdir --mode=755 "${TTYLINUX_BUILD_DIR}/kroot"
mkdir --mode=755 "${TTYLINUX_BUILD_DIR}/packages"
echo "DONE"

trap - EXIT

if [[ x"${TTYLINUX_ISOLINUX:-}" == x"y" ]]; then
	(
	build_config_setup
	cd "${TTYLINUX_BOOTLOADER_DIR}/isolinux"
	_version="${TTYLINUX_ISOLINUX_VERSION:-none}"
	_patch="${TTYLINUX_ISOLINUX_PATCH:-none}"
	_target="${TTYLINUX_ISOLINUX_TARGET:-none}"
	. ./bld.sh "${_version}" "${_patch}" "${_target}"
	exit 0
	)
fi

if [[ x"${TTYLINUX_UBOOT:-}" == x"y" ]]; then
	(
	build_config_setup
	cd "${TTYLINUX_BOOTLOADER_DIR}/uboot"
	_version="${TTYLINUX_UBOOT_VERSION:-none}"
	_patch="${TTYLINUX_UBOOT_PATCH:-none}"
	_target="${TTYLINUX_UBOOT_TARGET:-none}"
	. ./bld.sh "${_version}" "${_patch}" "${_target}"
	exit 0
	)
fi


# *****************************************************************************
# Exit OK
# *****************************************************************************

exit 0


# end of file
