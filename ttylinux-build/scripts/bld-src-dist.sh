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
#	This script builds the ttylinux packages.
#
# CHANGE LOG
#
#	18feb12	drj	File creation.
#
# *****************************************************************************


# *************************************************************************** #
#                                                                             #
# S U B R O U T I N E S                                                       #
#                                                                             #
# *************************************************************************** #


# *****************************************************************************
# Get the bootloader source packages, if any.
# *****************************************************************************

bootloader_sources_get() {

local destDir="${TTYLINUX_BUILD_DIR}/sources/bootloader"

rm --force --recursive "${destDir}"
mkdir --mode=755 "${destDir}"

echo -n "i> Getting bootloader files, if any .................. "

if [[ x"${TTYLINUX_ISOLINUX:-}" == x"y" ]]; then
	(
	cd "${TTYLINUX_BOOTLOADER_DIR}/isolinux"
	_version="${TTYLINUX_ISOLINUX_VERSION:-none}"
	_patch="${TTYLINUX_ISOLINUX_PATCH:-none}"
	. ./bld-src.sh "${_version}" "${_patch}" "${destDir}" "${manifest}"
	)
fi

if [[ x"${TTYLINUX_UBOOT:-}" == x"y" ]]; then
	(
	cd "${TTYLINUX_BOOTLOADER_DIR}/uboot"
	_version="${TTYLINUX_UBOOT_VERSION:-none}"
	_patch="${TTYLINUX_UBOOT_PATCH:-none}"
	. ./bld-src.sh "${_version}" "${_patch}" "${destDir}" "${manifest}"
	)
fi

echo "DONE"

}


# *****************************************************************************
# Get the source packages.
# *****************************************************************************

package_sources_get() {

local p=""
local t1=${SECONDS}
local t2=${SECONDS}
local srcPkgFile=""
local patchDir=""
local mins=0
local secs=0

local destDir="${TTYLINUX_BUILD_DIR}/sources/packages"

rm --force --recursive "${destDir}"
mkdir --mode=755 "${destDir}"

echo "i> Getting standard packages:"
for p in ${TTYLINUX_PACKAGE[@]}; do

	t1=${SECONDS}

	echo -n "${p} ";
	for ((i=(24-${#p}) ; i > 0 ; i--)); do echo -n "."; done

	set +o errexit
	srcPkgFile=$(ls "${TTYLINUX_PKGSRC_DIR}/${p}.t"* 2>/dev/null)
	set -o errexit
	if [[ -r "${srcPkgFile}" ]]; then
		cp "${srcPkgFile}" "${destDir}"
		echo -n " got it "
		echo -n "${p} " >>${manifest}
		for ((i=(40-${#p}) ; i > 0 ; i--)); do
			echo -n "." >>${manifest}
		done
		(
		. ${TTYLINUX_PKGCFG_DIR}/${p}/bld.sh
		echo " ${PKG_URL}"
		) >>${manifest}
	else
		echo -n " (none) "
	fi
	if [[ -d "${TTYLINUX_PKGCFG_DIR}/${p}/patch" ]]; then
		patchDir="${destDir}/${p}-patches"
		rm --force --recursive "${patchDir}"
		mkdir --mode=755 "${patchDir}"
		cp "${TTYLINUX_PKGCFG_DIR}/${p}/patch/"* "${patchDir}"
		echo -n "- got patch(s) "
		for _p in "${TTYLINUX_PKGCFG_DIR}/${p}/patch/"*; do
			if [[ -f "${_p}" ]]; then
				echo "=> patch: $(basename ${_p})" >>${manifest}
			fi
		done; unset _p
	else
		echo -n "- [no patches] "
	fi

	echo -n "... DONE ["
	t2=${SECONDS}
	mins=$(((${t2}-${t1})/60))
	secs=$(((${t2}-${t1})%60))
	[[ ${#mins} -eq 1 ]] && echo -n " "; echo -n "${mins} minutes "
	[[ ${#secs} -eq 1 ]] && echo -n " "; echo -n "${secs} seconds"
	echo "]"

done

}


# *****************************************************************************
# Get the tool-chain target source packages.
# *****************************************************************************

toolchain_target_sources_get() {

local destDir="${TTYLINUX_BUILD_DIR}/sources/tool-chain"

rm --force --recursive "${destDir}"
mkdir --mode=755 "${destDir}"

echo ""
echo -n "i> Getting Linux kernel and libc ..................... "

for file in "${TTYLINUX_XTOOL_DIR}/_pkg-src/"*; do
	[[ -r "${file}" ]] && cp "${file}" "${destDir}" || true
done

cat "${TTYLINUX_XTOOL_DIR}/_pkg-src/manifest.txt" >>${manifest}

echo "DONE"

}


# *****************************************************************************
# Get the platform patches and configuration files.
# *****************************************************************************

platform_config_get() {

local kernel="${TTYLINUX_PLATFORM_DIR}/kernel-${XBT_LINUX_VER#*-}"
local destDir="${TTYLINUX_BUILD_DIR}/sources/platform"

rm --force --recursive "${destDir}"
mkdir --mode=755 "${destDir}"

echo ""
echo -n "i> Getting platform configuration and patches ........ "

if [[ -r "${kernel}.cfg" ]]; then
	cp "${kernel}.cfg" "${destDir}"
	_f="$(basename ${kernel}.cfg)"
	echo "=> kernel config: ${_f}" >>${manifest}
	unset _f
fi

if [[ -r "${kernel}-add_in.tar.bz2" ]]; then
	cp "${kernel}-add_in.tar.bz2" "${destDir}"
	_f="$(basename ${kernel}-add_in.tar.bz2)"
	echo "=> kernel add-in: ${_f}" >>${manifest}
	unset _f
fi

for file in "${kernel}-??.patch"; do
	if [[ -r "${file}" ]]; then
		cp "${file}" "${destDir}"
		echo "=> kernel patch: $(basename ${file})" >>${manifest}
	fi
done; unset file

echo "DONE"

}


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

if [[ -z "${TTYLINUX_PACKAGE}" ]]; then
	echo "E> No packages to build.  How did you do that?" >&2
	exit 1
fi


# *****************************************************************************
# Main Program
# *****************************************************************************

echo ""
echo "##### START getting source packages"
echo ""

manifest="${TTYLINUX_BUILD_DIR}/sources/manifest.txt"

echo -n "i> Recreating source package staging directory ....... "
rm --force --recursive "${TTYLINUX_BUILD_DIR}/sources"
mkdir --mode=755 "${TTYLINUX_BUILD_DIR}/sources"
>"${manifest}"
echo "DONE"
echo ""

T1P=${SECONDS}

bootloader_sources_get
package_sources_get
toolchain_target_sources_get
platform_config_get

echo -n "i> Setting ownership and mode bits ................... "
find "${TTYLINUX_BUILD_DIR}/sources" -type d -exec chmod 755 {} \;
find "${TTYLINUX_BUILD_DIR}/sources" -type f -exec chmod 644 {} \;
echo "DONE"

echo -n "i> Creating CD-ROM ISO image ......................... "
rm --force ${TTYLINUX_SRC_NAME}
mkisofs -joliet                                                    \
        -rational-rock                                             \
        -output ${TTYLINUX_SRC_NAME}                               \
        -volid "ttylinux ${TTYLINUX_VERSION} ${TTYLINUX_PLATFORM}" \
        "${TTYLINUX_BUILD_DIR}/sources" >/dev/null 2>&1
echo "DONE"

echo ""
ls --color -hl ${TTYLINUX_SRC_NAME} | sed --expression="s|${TTYLINUX_DIR}/||"
echo ""

T2P=${SECONDS}
echo "=> $(((${T2P}-${T1P})/60)) minutes $(((${T2P}-${T1P})%60)) seconds"
echo ""

echo "##### DONE getting source packages"


# *****************************************************************************
# Exit OK
# *****************************************************************************

exit 0


# end of file
