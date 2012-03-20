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

PKG_URL="http://www.kernel.org/pub/linux/utils/kernel/hotplug/"
PKG_TAR="udev-182.tar.bz2"
PKG_SUM=""

PKG_NAME="udev"
PKG_VERSION="182"


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

PKG_STATUS="Unspecified error -- check the ${PKG_NAME} build log"

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
CFLAGS="${TTYLINUX_CFLAGS} -I${TTYLINUX_SYSROOT_DIR}/usr/include" \
BLKID_CFLAGS="-I${TTYLINUX_SYSROOT_DIR}/usr/include/blkid" \
BLKID_LIBS="-L/${TTYLINUX_SYSROOT_DIR}/lib -lblkid" \
KMOD_CFLAGS="-I${TTYLINUX_SYSROOT_DIR}/usr/include" \
KMOD_LIBS="-L/${TTYLINUX_SYSROOT_DIR}/lib -lkmod" \
./configure \
	--build=${MACHTYPE} \
	--host=${XBT_TARGET} \
	--prefix=/usr \
	--libdir=/usr/lib \
	--libexecdir=/lib \
	--sbindir=/sbin \
	--sysconfdir=/etc \
	--enable-rule_generator \
	--disable-gudev \
	--disable-introspection \
	--disable-keymap \
	--with-sysroot=${TTYLINUX_SYSROOT_DIR} \
	--with-rootlibdir=/lib \
	--with-rootprefix='' \
	--with-pci-ids-path=no \
	--with-usb-ids-path=no \
	--with-systemdsystemunitdir=no
source "${TTYLINUX_XTOOL_DIR}/_xbt_env_clr"
cd ..

# --with-rootprefix=DIR   rootfs directory prefix for config files and kernel
# --with-rootlibdir=DIR   rootfs directory to install shared libraries

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
PATH="${XBT_BIN_PATH}:${PATH}" make DESTDIR=${TTYLINUX_SYSROOT_DIR} install
for ruleFile in "${TTYLINUX_SYSROOT_DIR}/lib/udev/rules.d"/*; do
	sed --in-place \
		--expression="s/GROUP=\"dialout\"/GROUP=\"uucp\"/" \
		--expression="s/GROUP=\"tape\"/GROUP=\"disk\"/" \
		${ruleFile}
done; unset ruleFile
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
