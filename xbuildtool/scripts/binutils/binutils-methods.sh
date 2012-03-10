#!/bin/bash


# This file is NOT part of the kegel-initiated cross-tools software.
# This file is NOT part of the crosstool-NG software.
# This file IS part of the ttylinux xbuildtool software.
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
# PROGRAM INFORMATION
#
#	Developed by:	xbuildtool project
#	Developer:	Douglas Jerome, drj, <douglas@ttylinux.org>
#
# FILE DESCRIPTION
#
#	This script builds the cross-development binutils.
#
# CHANGE LOG
#
#	19feb12	drj	Added text manifest of tool chain components.
#	10feb12	drj	Added debug breaks.
#	01jan11	drj	Initial version from ttylinux cross-tools.
#
# *****************************************************************************


# *****************************************************************************
# xbt_resolve_binutils_name
# *****************************************************************************

# Usage: xbt_resolve_binutils_name <string>
#
# Uses:
#      XBT_SCRIPT_DIR
#
# Sets:
#     XBT_BINUTILS
#     XBT_BINUTILS_MD5SUM
#     XBT_BINUTILS_URL

xbt_resolve_binutils_name() {

source ${XBT_SCRIPT_DIR}/binutils/binutils-versions.sh

XBT_BINUTILS=""
XBT_BINUTILS_MD5SUM=""
XBT_BINUTILS_URL=""

for (( i=0 ; i<${#_BINUTILS[@]} ; i=(($i+1)) )); do
	if [[ "${1}" = "${_BINUTILS[$i]}" ]]; then
		XBT_BINUTILS="${_BINUTILS[$i]}"
		XBT_BINUTILS_MD5SUM="${_BINUTILS_MD5SUM[$i]}"
		XBT_BINUTILS_URL="${_BINUTILS_URL[$i]}"
		i=${#_BINUTILS[@]}
	fi
done

unset _BINUTILS
unset _BINUTILS_MD5SUM
unset _BINUTILS_URL

if [[ -z "${XBT_BINUTILS}" ]]; then
	echo "E> Cannot resolve \"${1}\""
	return 1
fi

return 0

}


# *****************************************************************************
# xbt_build_binutils
# *****************************************************************************

xbt_build_binutils() {

local msg
local ENABLE_BFD64

msg="Building ${XBT_BINUTILS} "
echo -n "${msg}"          >&${CONSOLE_FD}
xbt_print_dots_35 ${#msg} >&${CONSOLE_FD}
echo -n " "               >&${CONSOLE_FD}

xbt_debug_break ""

# Find, uncompress and untarr ${XBT_BINUTILS}.
#
xbt_src_get ${XBT_BINUTILS}

# Make an entry in the manifest.
#
echo -n "${XBT_BINUTILS} " >>"${XBT_TOOLCHAIN_MANIFEST}"
for ((i=(40-${#XBT_BINUTILS}) ; i > 0 ; i--)) do
	echo -n "." >>"${XBT_TOOLCHAIN_MANIFEST}"
done
echo " ${XBT_BINUTILS_URL}" >>"${XBT_TOOLCHAIN_MANIFEST}"

# Use any patches.
#
cd ${XBT_BINUTILS}
for p in ${XBT_PATCH_DIR}/${XBT_BINUTILS}-*.patch; do
	if [[ -f "${p}" ]]; then patch -Np1 -i "${p}"; fi
done; unset p
cd ..

# The Binutils documentation recommends building Binutils outside of the source
# directory in a dedicated build directory.
#
rm -rf	"build-binutils"
mkdir	"build-binutils"
cd	"build-binutils"

# Weird problem when building under ArchLinux i686 host: "makeinfo" is missing;
# it appears to be looking for bfd/docs/*.texi files in the build directory,
# even though they are actually in the source directory.
#
mkdir -p bfd/doc
cp -a ../${XBT_BINUTILS}/bfd/doc/* bfd/doc

ENABLE_BFD64=""
[[ "${XBT_LINUX_ARCH}" = "x86_64" ]] && ENABLE_BFD64="--enable-64-bit-bfd"

# Configure Binutils for building.
#
echo "# XBT_CONFIG **********"
../${XBT_BINUTILS}/configure \
	--build=${XBT_HOST} \
	--host=${XBT_HOST} \
	--target=${XBT_TARGET} \
	--prefix=${XBT_XHOST_DIR}/usr \
	${ENABLE_BFD64} \
	--enable-shared \
	--disable-multilib \
	--with-sysroot=${XBT_XTARG_DIR} || exit 1

xbt_debug_break "configured ${XBT_BINUTILS}"

# Build Binutils.
#
echo "# XBT_MAKE **********"
make LIB_PATH="${XBT_XTARG_DIR}/lib:${XBT_XTARG_DIR}/usr/lib" || exit 1

xbt_debug_break "maked ${XBT_BINUTILS}"

# Install Binutils.
#
echo "# XBT_INSTALL **********"
xbt_files_timestamp
#
make install || exit 1
#
echo "# XBT_FILES **********"
xbt_files_find

xbt_debug_break "installed ${XBT_BINUTILS}"

# Move out and clean up.
#
cd ..
rm -rf "build-binutils"
rm -rf "${XBT_BINUTILS}"

echo "done [${XBT_BINUTILS} is complete]" >&${CONSOLE_FD}

return 0

}


# end of file
