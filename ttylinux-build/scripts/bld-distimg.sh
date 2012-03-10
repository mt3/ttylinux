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
#	This script makes the ttylinux bootable ISO image file, or whatever
#	file is the final ttylinux binary distribution.
#
# CHANGE LOG
#
#	18feb12	drj	Rewrite for build process reorganization.
#	02feb12	drj	Removed BeagleBoard-xM, IntegratorCP, and MaltaLV.
#	01feb12	drj	Added BeagleBone.
#	09apr11	drj	Added wrtu54g_tm kernel+ramdisk binary.
#	30mar11	drj	Added wrtu54g_tm.  Changed away from ISO for some.
#	09feb11	drj	Removed the package list file "packages.txt".
#	24jan11	drj	Added the binary packages to the ISO image.
#	03jan11	drj	Added TTYLINUX_CLASS to kernel configuration file.
#	02jan11	drj	Added TTYLINUX_CLASS shell scripts added to ISO.
#	21dec10	drj	Changed for the new alternate Linux location.
#	11dec10	drj	Changed for the new config directory structure.
#	11dec10	drj	Changed for the new platform directory structure.
#	16nov10	drj	Reorganization of config/boot to config/kroot.
#	09oct10	drj	Minor simplifications.
#	17jul10	drj	Setup the initrd size kernel parameter for x86.
#	02apr10	drj	Changed for platform re-organization.
#	30mar10	drj	Renamed this file to build-iso.sh
#	28mar10	drj	Added the PowerPC ISO image.
#	26mar10	drj	Added the kernel vmlinux file to the ISO image.
#	23mar10	drj	Added the kernel System.map file to the ISO image.
#	05mar10	drj	Removed ttylinux.site-config.sh
#	07oct08	drj	File creation.
#
# *****************************************************************************


# *************************************************************************** #
#                                                                             #
# S U B R O U T I N E S                                                       #
#                                                                             #
# *************************************************************************** #


# *****************************************************************************
# Build the BeagleBone ttylinux binary distribution tarball.
# *****************************************************************************

tarball_bbone_make() {

pushd "${TTYLINUX_CONFIG_DIR}" >/dev/null 2>&1

echo -n "i> Zipping staging directory ......................... "
rm -rf ${TTYLINUX_TAR_NAME}
tar -C sdcard/ -cjf ${TTYLINUX_TAR_NAME} .
echo "DONE"

echo ""
ls --color -hl ${TTYLINUX_TAR_NAME} | sed --expression="s|${TTYLINUX_DIR}/||"
echo "i> distribution file $(basename ${TTYLINUX_TAR_NAME}) is ready."

popd >/dev/null 2>&1

return 0

}


# *****************************************************************************
# Build the WRTU54G-TM ttylinux binary distribution tarball.
# *****************************************************************************

tarball_wrtu54g_make() {

pushd "${TTYLINUX_BUILD_DIR}" >/dev/null 2>&1

echo -n "i> Zipping staging directory ......................... "
rm -rf ${TTYLINUX_TAR_NAME}
tar -C cdrom/ -cjf ${TTYLINUX_TAR_NAME} .
echo "DONE"

echo ""
ls --color -hl ${TTYLINUX_TAR_NAME} | sed --expression="s|${TTYLINUX_DIR}/||"
echo "i> distribution file $(basename ${TTYLINUX_TAR_NAME}) is ready."

popd >/dev/null 2>&1

return 0

}


# *****************************************************************************
# Build the Power Macintosh boot CD with the kernel and file system.
# *****************************************************************************

bootiso_pmac_make() {

pushd "${TTYLINUX_BUILD_DIR}" >/dev/null 2>&1

echo ""
echo "i> Creating CD-ROM ISO image ..."
find cdrom -type d -exec chmod 755 {} \;
find cdrom -type f -exec chmod 755 {} \;
mkisofs							\
	-v						\
	-J						\
	-l						\
	-r						\
	-hide-rr-moved					\
	-pad						\
	-o ${TTYLINUX_ISO_NAME}				\
	-V "ttylinux ${TTYLINUX_VERSION} ppc"		\
	-hfs -part					\
	-map "$(pwd)/cdrom/boot/hfsmap"			\
	-hfs-volid "ttylinux ${TTYLINUX_VERSION} ppc"	\
	-no-desktop					\
	-chrp-boot					\
	-prep-boot boot/yaboot				\
	-hfs-bless cdrom/boot				\
	cdrom
# -----------------------------------------------------------------------------
# Ben DeCamp's (ben@powerpup.yi.org):
#mkisofs -output $2                    \
#    -hfs-volid ttylinux ${SOURCE_VERSION} powerpc    \
#    -hfs -part -r -l -r -J -v            \
#    -map /boot/hfsmap            \
#    -no-desktop                    \
#    -chrp-boot                    \
#    -prep-boot boot/yaboot                \
#    -hfs-bless /boot            \
#    $1
# -----------------------------------------------------------------------------
#mkisofs				\
#	-hide-rr-moved			\
#	-hfs				\
#	-part				\
#	-map ./ttylinux/boot/hfsmap	\
#	-no-desktop			\
#	-hfs-volid ttylinux		\
#	-hfs-bless ./ttylinux/boot	\
#	-pad				\
#	-l				\
#	-r				\
#	-J				\
#	-v				\
#	-V ttylinux			\
#	-o ttylinux.iso			\
#	./ttylinux
# -----------------------------------------------------------------------------
# mkisofs \
#	-o boot.iso -chrp-boot -U \
#	-prep-boot ppc/chrp/yaboot \
#	-part -hfs -T -r -l -J \
#	-A "Fedora 4" -sysid PPC -V "PBOOT" -volset 4 -volset-size 1 \
#	-volset-seqno 1 -hfs-volid 4 -hfs-bless $(pwd)/ppc/ppc \
#	-map mapping -magic magic -no-desktop -allow-multidot \
#	$(pwd)/ppc
# -----------------------------------------------------------------------------
# echo "ofboot.b X 'chrp' 'tbxi'" > mapping
# volume_id="PBOOT"
# system_id="PPC"
# volume_set_id="6";
# application_id="Fedora Core 6"
# hfs_volume_id=$volume_set_id
# mkisofs \
#	-volid "$volume_id" -sysid "$system_id" -appid "$application_id" \
#	-volset "$volume_set_id" -untranslated-filenames -joliet \
#	-rational-rock -translation-table -hfs -part \
#	-hfs-volid "$hfs_volume_id" -no-desktop -hfs-creator '????' \
#	-hfs-type '????' -map "$(pwd)/mapping" -chrp-boot \
#	-prep-boot ppc/chrp/yaboot -hfs-bless "$(pwd)/boot-new/ppc/mac" \
#	-o boot-new.iso $(pwd)/boot-new
# -----------------------------------------------------------------------------
echo "... DONE"

echo ""
ls --color -hl ${TTYLINUX_ISO_NAME} | sed --expression="s|${TTYLINUX_DIR}/||"
echo "i> ISO image file $(basename ${TTYLINUX_ISO_NAME}) is ready."

popd >/dev/null 2>&1

return 0

}


# *****************************************************************************
# Build the x86 boot CD with the kernel and file system.
# *****************************************************************************

bootiso_x86_make() {

pushd "${TTYLINUX_BUILD_DIR}" >/dev/null 2>&1

echo ""
echo "i> Creating CD-ROM ISO image ..."
find cdrom -type d -exec chmod 755 {} \;
find cdrom -type f -exec chmod 755 {} \;
mkisofs	-joliet							\
	-rational-rock						\
	-output ${TTYLINUX_ISO_NAME}				\
	-volid "ttylinux ${TTYLINUX_VERSION} ${TTYLINUX_CPU}"	\
	-eltorito-boot boot/isolinux/isolinux.bin		\
	-eltorito-catalog boot/isolinux/boot.cat		\
	-boot-info-table					\
	-boot-load-size 4					\
	-no-emul-boot						\
	cdrom
echo "... DONE"

echo ""
ls --color -hl ${TTYLINUX_ISO_NAME} | sed --expression="s|${TTYLINUX_DIR}/||"
echo "i> ISO image file $(basename ${TTYLINUX_ISO_NAME}) is ready."

popd >/dev/null 2>&1

return 0

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


# *****************************************************************************
# Main Program
# *****************************************************************************

echo "##### START cross-building the boot image"
echo ""

[[ "${TTYLINUX_PLATFORM}" == "beagle_bone"   ]] && tarball_bbone_make   || true
[[ "${TTYLINUX_PLATFORM}" == "mac_g4"        ]] && bootiso_pmac_make    || true
[[ "${TTYLINUX_PLATFORM}" == "pc_i486"       ]] && bootiso_x86_make     || true
[[ "${TTYLINUX_PLATFORM}" == "pc_i686"       ]] && bootiso_x86_make     || true
[[ "${TTYLINUX_PLATFORM}" == "pc_x86_64"     ]] && bootiso_x86_make     || true
[[ "${TTYLINUX_PLATFORM}" == "wrtu54g_tm"    ]] && tarball_wrtu54g_make || true

echo ""
echo "##### DONE cross-building the boot image"


# *****************************************************************************
# Exit OK
# *****************************************************************************

exit 0


# end of file
