#!/bin/bash


# This file is part of the ttylinux software.
# The license which this software falls under is GPLv2 as follows:
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

PKG_URL="http://www.kernel.org/pub/linux/utils/util-linux-ng/v2.18"
PKG_TAR="util-linux-ng-2.18.tar.bz2"
PKG_SUM=""

PKG_NAME="util-linux-ng"
PKG_VERSION="2.18"


# ******************************************************************************
# pkg_patch
# ******************************************************************************

pkg_patch() {

PKG_STATUS="Unspecified error -- check the ${PKG_NAME} build log"

# The FHS recommends using the /var/lib/hwclock directory instead of the usual
# /etc directory as the location for the adjtime file.  To make the hwclock
# program FHS-compliant, run the following:
# sed -e 's@etc/adjtime@var/lib/hwclock/adjtime@g' \
#	-i $(grep -rl '/etc/adjtime' .)
# mkdir -pv /var/lib/hwclock

PKG_STATUS=""
return 0

}


# ******************************************************************************
# pkg_configure
# ******************************************************************************

pkg_configure() {

PKG_STATUS="Unspecified error -- check the ${PKG_NAME} build log"

# clfs:
# --enable-login-utils
# --disable-makeinstall-chown

# lfs:
# --enable-arch  Enables building the arch program
# --enable-partx Enables building the addpart, delpart and partx programs
# --enable-write Enables building the write program

#  --disable-libuuid       do not build libuuid and uuid utilities
#  --disable-uuidd         do not build the uuid daemon
#  --disable-libblkid      do not build libblkid and blkid utilities
#  --disable-libmount      do not build libmount

cd "${PKG_NAME}-${PKG_VERSION}"
source "${TTYLINUX_XTOOL_DIR}/_xbt_env_set"
AR="${XBT_AR}" \
AS="${XBT_AS} --sysroot=${TTYLINUX_SYSROOT_DIR}" \
CC="${XBT_CC} --sysroot=${TTYLINUX_SYSROOT_DIR}" \
CXX="${XBT_CXX} --sysroot=${TTYLINUX_SYSROOT_DIR}" \
LD="${XBT_LD} --sysroot=${TTYLINUX_SYSROOT_DIR}" \
NM="${XBT_NM}" \
OBJCOPY="${XBT_OBJCOPY}" \
RANLIB="${XBT_RANLIB}" \
SIZE="${XBT_SIZE}" \
STRIP="${XBT_STRIP}" \
CFLAGS="${TTYLINUX_CFLAGS}" \
./configure \
	--build=${MACHTYPE} \
	--host=${XBT_TARGET} \
	--disable-makeinstall-chown \
	--disable-shared \
	--without-ncurses
source "${TTYLINUX_XTOOL_DIR}/_xbt_env_clr"
cd ..

PKG_STATUS=""
return 0

}


# ******************************************************************************
# pkg_make
# ******************************************************************************

pkg_make() {

PKG_STATUS="Unspecified error -- check the ${PKG_NAME} build log"

cd "${PKG_NAME}-${PKG_VERSION}"
source "${TTYLINUX_XTOOL_DIR}/_xbt_env_set"
PATH="${XBT_BIN_PATH}:${PATH}" make --jobs=${NJOBS} CROSS_COMPILE=${XBT_TARGET}-
source "${TTYLINUX_XTOOL_DIR}/_xbt_env_clr"
cd ..

PKG_STATUS=""
return 0

}


# ******************************************************************************
# pkg_install
# ******************************************************************************

pkg_install() {

PKG_STATUS="Unspecified error -- check the ${PKG_NAME} build log"

cd "${PKG_NAME}-${PKG_VERSION}"
source "${TTYLINUX_XTOOL_DIR}/_xbt_env_set"
#PATH="${XBT_BIN_PATH}:${PATH}" make \
#	CROSS_COMPILE=${XBT_TARGET}- \
#	DESTDIR=${TTYLINUX_SYSROOT_DIR} \
#	install
instCmd="install --mode=755 --group=0 --owner=0"
${instCmd} mount/losetup ${TTYLINUX_SYSROOT_DIR}/sbin/
unset instCmd
source "${TTYLINUX_XTOOL_DIR}/_xbt_env_clr"
cd ..

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
