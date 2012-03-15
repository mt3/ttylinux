#!/bin/bash


# This file is part of the ttylinux software.
# The license which this software falls under is as follows:
#
# Copyright (C) 2010-2012 Douglas Jerome <douglas@ttylinux.org>
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


# ******************************************************************************
# Definitions
# ******************************************************************************

PKG_URL="(cross-tools)"
PKG_TAR=""
PKG_SUM=""

PKG_NAME="glibc-devel"
PKG_VERSION="2.14"


# ******************************************************************************
# pkg_patch
# ******************************************************************************

pkg_patch() {
PKG_STATUS=""
return 0
}


# ******************************************************************************
# pkg_configure
# ******************************************************************************

pkg_configure() {
PKG_STATUS=""
return 0
}


# ******************************************************************************
# pkg_make
# ******************************************************************************

pkg_make() {
PKG_STATUS=""
return 0
}


# ******************************************************************************
# pkg_install
# ******************************************************************************

pkg_install() {

local xtoolTargDir="${TTYLINUX_XTOOL_DIR}/target"

PKG_STATUS="Unspecified error -- check the ${PKG_NAME} build log"

echo "Copying cross-tool ${PKG_NAME} target components to build-root."
_targDir=${TTYLINUX_SYSROOT_DIR}
cp --no-dereference ${xtoolTargDir}/usr/lib/*.a ${_targDir}/usr/lib
cp --no-dereference ${xtoolTargDir}/usr/lib/*.o ${_targDir}/usr/lib
cp --no-dereference --recursive \
	${xtoolTargDir}/usr/include/* \
	${_targDir}/usr/include
unset _targDir

echo "Copying ${PKG_NAME} ttylinux-specific components to build-root."
if [[ -d "rootfs/" ]]; then
	find "rootfs/" ! -type d -exec touch {} \;
	cp --archive --force rootfs/* "${TTYLINUX_SYSROOT_DIR}"
fi

PKG_STATUS=""
return 0

}


# ******************************************************************************
# pkg_clean
# ******************************************************************************

pkg_clean() {
PKG_STATUS=""
return 0
}


# end of file
