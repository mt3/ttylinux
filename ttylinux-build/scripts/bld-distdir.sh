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
#	This script makes the ttylinux distribution staging directory.
#
# CHANGE LOG
#
#	18feb12	drj	Rewrite for build process reorganization.
#	02feb12	drj	Only make the distribution directory, not ISO image.
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
# Assemble the BeagleBone distribution directory.
# *****************************************************************************

bbone_dir_make() {

local kver="${XBT_LINUX_VER#*-}"
local kname="kernel-${kver}-${TTYLINUX_CLASS}-${TTYLINUX_CPU}"
local kcfg="${TTYLINUX_PLATFORM_DIR}/${kname}.cfg"

# If TTYLINUX_KERNEL is set, as specified in the ttylinux-config.sh file,
# then there is a non-standard (user custom) ttylinux kernel to build, in which
# case the linux source distribution and kernel configuration file is supposed
# to be in the ttylinux site/platform-* directory.
#
if [[ -n "${TTYLINUX_KERNEL}" ]]; then
	srcd="${TTYLINUX_DIR}/site/$(basename ${TTYLINUX_PLATFORM_DIR})"
	kver="${TTYLINUX_KERNEL}"
	kcfg="${srcd}/kernel-${TTYLINUX_KERNEL}.cfg"
	unset srcd
fi

pushd "${TTYLINUX_CONFIG_DIR}" >/dev/null 2>&1

echo -n "i> Recreating boot staging directory ................. "
rm --force --recursive "sdcard/"
mkdir --mode=755 "sdcard/"
mkdir --mode=755 "sdcard/boot/"
mkdir --mode=755 "sdcard/config/"
mkdir --mode=755 "sdcard/doc/"
mkdir --mode=755 "sdcard/packages/"
echo "DONE"

echo -n "i> Gathering boot files .............................. "
>sdcard/LABEL
echo "SOURCE_TIMESTAMP=\"$(date)\""           >>sdcard/LABEL
echo "SOURCE_MEDIA=\"UNKNOWN\""               >>sdcard/LABEL
echo "SOURCE_VERSION=\"${TTYLINUX_VERSION}\"" >>sdcard/LABEL
echo "SOURCE_ARCH=\"${TTYLINUX_CPU}\""        >>sdcard/LABEL
echo "SOURCE_KVER=\"${kver}\""                >>sdcard/LABEL
cp ${TTYLINUX_DOC_DIR}/AUTHORS       sdcard/AUTHORS
cp ${TTYLINUX_DOC_DIR}/COPYING       sdcard/COPYING
cp bootloader-uboot/MLO              sdcard/boot/MLO
cp bootloader-uboot/u-boot.bin       sdcard/boot/u-boot.img
cp ${TTYLINUX_IMG_NAME}              sdcard/boot/filesys
cp kroot/boot/System.map             sdcard/boot/System.map
cp kroot/boot/uImage                 sdcard/boot/uImage
cp kroot/boot/vmlinux                sdcard/boot/vmlinux
cp ${TTYLINUX_PLATFORM_DIR}/uEnv.txt sdcard/boot/uEnv.txt
chmod 644 sdcard/AUTHORS
chmod 644 sdcard/COPYING
chmod 644 sdcard/LABEL
chmod 644 sdcard/boot/*
chmod 755 sdcard/boot/vmlinux
echo "DONE"

echo -n "i> Compress the file system .......................... "
gzip --no-name sdcard/boot/filesys
echo "DONE"

echo -n "i> Copying configuration data and tools .............. "
cp ${kcfg} sdcard/config/kernel-${kver}.cfg
chmod 644 sdcard/config/kernel-${kver}.cfg
for f in ${TTYLINUX_PLATFORM_DIR}/*-${TTYLINUX_CLASS}-${TTYLINUX_CPU}.sh; do
	[[ -r "${f}" ]] && cp ${f} sdcard/ && chmod 755 sdcard/${f} || true
done
echo "DONE"

echo -n "i> Copying documentation files ....................... "
_chgLog="ChangeLog-${TTYLINUX_CLASS}-${TTYLINUX_CPU}"
cp ${TTYLINUX_DOC_DIR}/${_chgLog}      sdcard/doc/
cp ${TTYLINUX_DOC_DIR}/User_Guide.html sdcard/doc/
cp ${TTYLINUX_DOC_DIR}/User_Guide.pdf  sdcard/doc/
cp ${TTYLINUX_DOC_DIR}/User_Guide.tex  sdcard/doc/
unset _chgLog
chmod 644 sdcard/doc/*
echo "DONE"

echo -n "i> Copying packages .................................. "
cp ${TTYLINUX_PKGBIN_DIR}/* sdcard/packages/
chmod 644 sdcard/packages/*
echo "DONE"

popd >/dev/null 2>&1

return 0

}


# *****************************************************************************
# Assemble the Power Macintosh distribution directory.
# *****************************************************************************

mac_dir_make() {

local kver="${XBT_LINUX_VER#*-}"
local kcfg="${TTYLINUX_PLATFORM_DIR}/kernel-${kver}.cfg"
local rdSize=$((${TTYLINUX_RAMDISK_SIZE}*1024))

# If TTYLINUX_KERNEL is set, as specified in the ttylinux-config.sh file,
# then there is a non-standard (user custom) ttylinux kernel to build, in which
# case the linux source distribution and kernel configuration file is supposed
# to be in the ttylinux site/platform-* directory.
#
if [[ -n "${TTYLINUX_USER_KERNEL:-}" ]]; then
	srcd="${TTYLINUX_DIR}/site/platform-${TTYLINUX_PLATFORM}"
	kcfg="${srcd}/kernel-${TTYLINUX_USER_KERNEL}.cfg"
	unset srcd
fi

pushd "${TTYLINUX_BUILD_DIR}" >/dev/null 2>&1

echo -n "i> Recreating ISO directory .......................... "
rm --force --recursive "cdrom/"
mkdir --mode=755 "cdrom/"
mkdir --mode=755 "cdrom/boot/"
mkdir --mode=755 "cdrom/config/"
mkdir --mode=755 "cdrom/doc/"
mkdir --mode=755 "cdrom/packages/"
mkdir --mode=755 "cdrom/ppc/"
mkdir --mode=755 "cdrom/ppc/chrp/"
echo "DONE"

echo -n "i> Gathering boot files .............................. "
>cdrom/LABEL
echo "SOURCE_TIMESTAMP=\"$(date)\""           >>cdrom/LABEL
echo "SOURCE_MEDIA=\"CDROM\""                 >>cdrom/LABEL
echo "SOURCE_VERSION=\"${TTYLINUX_VERSION}\"" >>cdrom/LABEL
echo "SOURCE_ARCH=\"${TTYLINUX_CPU}\""        >>cdrom/LABEL
echo "SOURCE_KVER=\"${kver}\""                >>cdrom/LABEL
cp ${TTYLINUX_DOC_DIR}/AUTHORS cdrom/AUTHORS
cp ${TTYLINUX_DOC_DIR}/COPYING cdrom/COPYING
chmod 644 cdrom/AUTHORS cdrom/COPYING
cp ${TTYLINUX_BOOTLOADER_DIR}/yaboot/boot.msg     cdrom/boot/boot.msg
cp ${TTYLINUX_BOOTLOADER_DIR}/yaboot/hfsmap       cdrom/boot/hfsmap
cp ${TTYLINUX_BOOTLOADER_DIR}/yaboot/ofboot.b     cdrom/boot/ofboot.b
cp ${TTYLINUX_SYSROOT_DIR}/usr/lib/yaboot/yaboot  cdrom/boot/yaboot
cp ${TTYLINUX_BOOTLOADER_DIR}/yaboot/yaboot.conf  cdrom/boot/yaboot.conf
cp ${TTYLINUX_BOOTLOADER_DIR}/yaboot/bootinfo.txt cdrom/ppc/bootinfo.txt
chmod 644 cdrom/boot/boot.msg
chmod 644 cdrom/boot/hfsmap
chmod 644 cdrom/boot/ofboot.b
chmod 644 cdrom/boot/yaboot.conf
chmod 644 cdrom/ppc/bootinfo.txt
cp ${TTYLINUX_IMG_NAME}  cdrom/boot/filesys
cp kroot/boot/System.map cdrom/boot/System.map
cp kroot/boot/vmlinux    cdrom/boot/vmlinux
cp kroot/boot/zImage     cdrom/boot/vmlinuz
echo "DONE"

echo -n "i> Compress the file system .......................... "
gzip --no-name cdrom/boot/filesys
echo "DONE"

echo -n "i> Set the initrd file system size ................... "
sed --in-place \
	--expression="s/ramdisk_size=[0-9]*/ramdisk_size=${rdSize}/" \
	cdrom/boot/yaboot.conf
sed --in-place \
	--expression="s/ramdisk_size=[0-9]*/ramdisk_size=${rdSize}/" \
	cdrom/yaboot.conf
echo "DONE"

echo ""
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
cat cdrom/boot/yaboot.conf
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo ""

echo -n "i> Copying configuration data and tools to Boot CD ... "
sed --in-place \
	--expression="s/ramdisk_size=[0-9]*/ramdisk_size=${rdSize}/" \
	${TTYLINUX_PLATFORM_DIR}/qemu-${TTYLINUX_CPU}.sh
cp ${kcfg} cdrom/config/kernel-${kver}.cfg
for f in ${TTYLINUX_PLATFORM_DIR}/*.sh; do
	[[ -r "${f}" ]] && cp ${f} cdrom/ || true
done
chmod 644 cdrom/config/kernel-${kver}.cfg
chmod 755 cdrom/*.sh
echo "DONE"

echo -n "i> Copying documentation files to Boot CD ............ "
_chgLog="ChangeLog-${TTYLINUX_PLATFORM}"
cp ${TTYLINUX_DOC_DIR}/${_chgLog}      cdrom/doc/
cp ${TTYLINUX_DOC_DIR}/User_Guide.html cdrom/doc/
cp ${TTYLINUX_DOC_DIR}/User_Guide.pdf  cdrom/doc/
cp ${TTYLINUX_DOC_DIR}/User_Guide.tex  cdrom/doc/
unset _chgLog
chmod 644 cdrom/doc/*
echo "DONE"

echo -n "i> Copying packages to Boot CD ....................... "
cp ${TTYLINUX_PKGBIN_DIR}/* cdrom/packages/
echo "DONE"

popd >/dev/null 2>&1

return 0

}


# *****************************************************************************
# Assemble the PC distribution directory.
# *****************************************************************************

pc_dir_make() {

local kver="${TTYLINUX_USER_KERNEL:-${XBT_LINUX_VER##*-}}"
local kcfg="${TTYLINUX_PLATFORM_DIR}/kernel-${kver}.cfg"
local rdSize

# If TTYLINUX_KERNEL is set, as specified in the ttylinux-config.sh file,
# then there is a non-standard (user custom) ttylinux kernel to build, in which
# case the linux source distribution and kernel configuration file is supposed
# to be in the ttylinux site/platform-* directory.
#
if [[ -n "${TTYLINUX_USER_KERNEL:-}" ]]; then
	srcd="${TTYLINUX_DIR}/site/platform-${TTYLINUX_PLATFORM}"
	kcfg="${srcd}/kernel-${TTYLINUX_USER_KERNEL}.cfg"
	unset srcd
fi

pushd "${TTYLINUX_BUILD_DIR}" >/dev/null 2>&1

echo -n "i> Recreating ISO directory .......................... "
rm --force --recursive "cdrom/"
mkdir --mode=755 "cdrom/"
mkdir --mode=755 "cdrom/boot/"
mkdir --mode=755 "cdrom/boot/grub"
mkdir --mode=755 "cdrom/boot/isolinux/"
mkdir --mode=755 "cdrom/config/"
mkdir --mode=755 "cdrom/doc/"
mkdir --mode=755 "cdrom/packages/"
echo "DONE"

echo -n "i> Gathering boot files .............................. "
>cdrom/LABEL
echo "SOURCE_TIMESTAMP=\"$(date)\""           >>cdrom/LABEL
echo "SOURCE_MEDIA=\"CDROM\""                 >>cdrom/LABEL
echo "SOURCE_VERSION=\"${TTYLINUX_VERSION}\"" >>cdrom/LABEL
echo "SOURCE_ARCH=\"${TTYLINUX_CPU}\""        >>cdrom/LABEL
echo "SOURCE_KVER=\"${kver}\""                >>cdrom/LABEL
cp ${TTYLINUX_DOC_DIR}/AUTHORS cdrom/AUTHORS
cp ${TTYLINUX_DOC_DIR}/COPYING cdrom/COPYING
chmod 644 cdrom/AUTHORS cdrom/COPYING
cp ${TTYLINUX_PLATFORM_DIR}/loopback.cfg cdrom/boot/grub/loopback.cfg
chmod 644 cdrom/boot/grub/loopback.cfg
_dest="cdrom/boot/isolinux"
cp ${TTYLINUX_BOOTLOADER_DIR}/isolinux/isolinux.bin ${_dest}/isolinux.bin
cp ${TTYLINUX_BOOTLOADER_DIR}/isolinux/isolinux.cfg ${_dest}/isolinux.cfg
cp ${TTYLINUX_BOOTLOADER_DIR}/isolinux/boot.msg     ${_dest}/boot.msg
cp ${TTYLINUX_BOOTLOADER_DIR}/isolinux/help_f2.msg  ${_dest}/help_f2.msg
cp ${TTYLINUX_BOOTLOADER_DIR}/isolinux/help_f3.msg  ${_dest}/help_f3.msg
cp ${TTYLINUX_BOOTLOADER_DIR}/isolinux/help_f4.msg  ${_dest}/help_f4.msg
unset _dest
chmod 644 cdrom/boot/isolinux/*
cp ${TTYLINUX_IMG_NAME}  cdrom/boot/filesys
cp kroot/boot/System.map cdrom/boot/System.map
cp kroot/boot/vmlinux    cdrom/boot/vmlinux
cp kroot/boot/bzImage    cdrom/boot/vmlinuz
echo "DONE"

echo -n "i> Compress the root file system initrd .............. "
gzip --no-name cdrom/boot/filesys
echo "DONE"

echo -n "i> Set the initrd file system size ................... "
rdSize=$((${TTYLINUX_RAMDISK_SIZE}*1024))
sed --in-place \
	--expression="s/root=/ramdisk_size=${rdSize} root=/" \
	cdrom/boot/isolinux/isolinux.cfg
echo "DONE"

echo ""
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
cat cdrom/boot/isolinux/isolinux.cfg
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo ""

echo -n "i> Copying configuration data and tools to Boot CD ... "
sed --in-place \
	--expression="s/ramdisk_size=[0-9]*/ramdisk_size=${rdSize}/" \
	${TTYLINUX_PLATFORM_DIR}/qemu-${TTYLINUX_CPU}.sh
cp ${kcfg}                                      cdrom/config/kernel-${kver}.cfg
cp ${TTYLINUX_BOOTLOADER_DIR}/isolinux/syslinux cdrom/config/
cp ${TTYLINUX_CONFIG_DIR}/ttylinux-setup        cdrom/config/
for f in ${TTYLINUX_PLATFORM_DIR}/*.sh; do
	[[ -r "${f}" ]] && cp ${f} cdrom/ || true
done
chmod 644 cdrom/config/*.cfg
chmod 755 cdrom/config/ttylinux-setup
chmod 755 cdrom/*.sh
echo "DONE"

echo -n "i> Copying documentation files to Boot CD ............ "
_chgLog="ChangeLog-${TTYLINUX_PLATFORM}"
cp ${TTYLINUX_DOC_DIR}/${_chgLog}           cdrom/doc/
cp ${TTYLINUX_DOC_DIR}/Flash_Disk_Howto.txt cdrom/doc/
cp ${TTYLINUX_DOC_DIR}/User_Guide.html      cdrom/doc/
cp ${TTYLINUX_DOC_DIR}/User_Guide.pdf       cdrom/doc/
cp ${TTYLINUX_DOC_DIR}/User_Guide.tex       cdrom/doc/
unset _chgLog
chmod 644 cdrom/doc/*
echo "DONE"

echo -n "i> Copying packages to Boot CD ....................... "
cp ${TTYLINUX_PKGBIN_DIR}/* cdrom/packages/
echo "DONE"

popd >/dev/null 2>&1

return 0

}


# *****************************************************************************
# Assemble the WRTU54G-TM distribution directory.
# *****************************************************************************

# The string used with the mkimage -n option for the kernel image name must be
# "ADM8668 Linux Kernel(2.4.31)" for the vendor bootloader, otherwise the the
# vendor bootloader won't run the kernel.

wrtu54g_bin_make() {

# This function shamelessly nicked from Scott Nicholas <neutronscott@scottn.us>
# Copyright (C) 2011 Scott Nicholas <neutronscott@scottn.us>
#
# The binary kernel is padded to 64k boundary and the ramdisk is appened.
# u-boot mkimage puts a 64 byte header on the kernel and a 12 byte header on
# the ramdisk, so the kernel size is addjusted so the ramdisk binary begins
# on a 64KB boundary.

local sysmap="kroot/boot/System.map"
local kernel="cdrom/boot/vmlinux.bin"
local ramdisk="cdrom/boot/filesys.gz"
local kernelLoad_H=""
local kernelLoad_D=0
local kernelEntry_H=""
local kernelEntry_D=0
local origKernelSize=0
local kernelSize=0

kernelLoad_H=$(grep "A _text" ${sysmap} | cut -d ' ' -f 1)
kernelLoad_H=${kernelLoad_H#ffffffff}
kernelLoad_D=$((0x${kernelLoad_H#ffffffff})) # Convert hex to decimal

KernelEntry_H=$(grep "T kernel_entry" ${sysmap} | cut -d ' ' -f 1)
KernelEntry_H=${KernelEntry_H#ffffffff}
kernelEntry_D=$((0x${KernelEntry_H#ffffffff})) # Convert hex to decimal

origKernelSize=$(stat -c%s ${kernel})
kernelSize=$(((${origKernelSize} / 65536 + 1) * 65536 - 64 - 12))
if [[ ${kernelSize} -lt ${origKernelSize} ]]; then
	kernelSize=$((${kernelSize} + 65536))
fi

printf "kernel_load  == 0x%08x\n" ${kernelLoad_D}
printf "kernel_entry == 0x%08x\n" ${kernelEntry_D}
printf "kernel_size  == 0x%08x\n" ${kernelSize}
printf "ramdisk_offs == 0x%08x\n" $((${kernelSize} + 64 + 12 ))
printf "ramdisk_load == kernel_load + ramdisk_offset == 0x%08x\n" \
	$((${kernelLoad_D} + ${kernelSize} + 64 + 12 ))

dd if=${kernel}  of=aligned.kernel  bs=${kernelSize} conv=sync >/dev/null 2>&1
dd if=${ramdisk} of=aligned.ramdisk bs=64k           conv=sync >/dev/null 2>&1

${TTYLINUX_BOOTLOADER_DIR}/uboot/mkimage \
	-A mips \
	-O linux \
	-T multi \
	-C none \
	-a 0x${kernelLoad_H} \
	-e 0x${KernelEntry_H} \
	-n "ADM8668 Linux Kernel(2.4.31)" \
	-d aligned.kernel:aligned.ramdisk \
	cdrom/boot/vmlinux-ramdisk.bin

rm aligned.kernel
rm aligned.ramdisk

}

# *****************************************************************************

wrtu54g_dir_make() {

local kver="${TTYLINUX_USER_KERNEL:-${XBT_LINUX_VER##*-}}"
local kcfg="${TTYLINUX_PLATFORM_DIR}/kernel-${kver}.cfg"

# If TTYLINUX_KERNEL is set, as specified in the ttylinux-config.sh file,
# then there is a non-standard (user custom) ttylinux kernel to build, in which
# case the linux source distribution and kernel configuration file is supposed
# to be in the ttylinux site/platform-* directory.
#
if [[ -n "${TTYLINUX_USER_KERNEL:-}" ]]; then
	srcd="${TTYLINUX_DIR}/site/platform-${TTYLINUX_PLATFORM}"
	kcfg="${srcd}/kernel-${TTYLINUX_USER_KERNEL}.cfg"
	unset srcd
fi

pushd "${TTYLINUX_BUILD_DIR}" >/dev/null 2>&1

echo -n "i> Recreating boot staging directory ................. "
rm --force --recursive "cdrom/"
mkdir --mode=755 "cdrom/"
mkdir --mode=755 "cdrom/boot/"
mkdir --mode=755 "cdrom/config/"
mkdir --mode=755 "cdrom/doc/"
mkdir --mode=755 "cdrom/packages/"
echo "DONE"

echo -n "i> Gathering boot files .............................. "
>cdrom/LABEL
echo "SOURCE_TIMESTAMP=\"$(date)\""           >>cdrom/LABEL
echo "SOURCE_MEDIA=\"UNKNOWN\""               >>cdrom/LABEL
echo "SOURCE_VERSION=\"${TTYLINUX_VERSION}\"" >>cdrom/LABEL
echo "SOURCE_ARCH=\"${TTYLINUX_CPU}\""        >>cdrom/LABEL
echo "SOURCE_KVER=\"${kver}\""                >>cdrom/LABEL
cp ${TTYLINUX_DOC_DIR}/AUTHORS cdrom/AUTHORS
cp ${TTYLINUX_DOC_DIR}/COPYING cdrom/COPYING
chmod 644 cdrom/AUTHORS cdrom/COPYING
cp ${TTYLINUX_IMG_NAME}        cdrom/boot/filesys
cp kroot/boot/System.map       cdrom/boot/System.map
cp kroot/boot/vmlinux          cdrom/boot/vmlinux
echo "DONE"

echo -n "i> Creating binary vmlinux.bin from elf vmlinux ...... "
source "${TTYLINUX_XTOOL_DIR}/_xbt_env_set"
PATH="${XBT_BIN_PATH}:${PATH}" ${XBT_TARGET}-objcopy \
	-O binary -S cdrom/boot/vmlinux cdrom/boot/vmlinux.bin
source "${TTYLINUX_XTOOL_DIR}/_xbt_env_clr"
echo "DONE"

echo -n "i> Compressing root file system initrd: filesys.gz ... "
gzip cdrom/boot/filesys
echo "DONE"

echo "   -------------------------------------------------------"
echo "i> Making flash load binary kernel+ramdisk"
wrtu54g_bin_make cdrom/boot/vmlinux-ramdisk.bin
echo "   -------------------------------------------------------"

echo -n "i> Making uImage with vimlinux.bin.gz for u-boot ..... "
gzip cdrom/boot/vmlinux.bin
${TTYLINUX_BOOTLOADER_DIR}/uboot/mkimage \
	-A mips \
	-O linux \
	-T kernel \
	-C gzip \
	-a 0x80002000 \
	-e 0x80006220  \
	-n "ADM8668 Linux Kernel(2.4.31)" \
	-d cdrom/boot/vmlinux.bin.gz \
	cdrom/boot/uImage >/dev/null 2>&1
gunzip cdrom/boot/vmlinux.bin.gz
echo "DONE"

echo -n "i> Making ramdisk.gz with filesys.gz for u-boot ...... "
${TTYLINUX_BOOTLOADER_DIR}/uboot/mkimage \
	-A mips \
	-O linux \
	-T ramdisk \
	-C gzip \
	-a 0 \
	-e 0 \
	-n "ramdisk" \
	-d cdrom/boot/filesys.gz \
	cdrom/boot/ramdisk.gz >/dev/null 2>&1
echo "DONE"

echo -n "i> Removing compressed root file system filesys.gz ... "
rm -rf cdrom/boot/filesys.gz
echo "DONE"

echo -n "i> Copying configuration data and tools .............. "
cp ${kcfg} cdrom/config/kernel-${kver}.cfg
chmod 644 cdrom/config/*.cfg
for f in ${TTYLINUX_PLATFORM_DIR}/*.sh; do
	[[ -r "${f}" ]] && cp ${f} cdrom/ || true
done
for f in cdrom/*.sh; do
	[[ -r "${f}" ]] && chmod 755 ${f} || true
done
echo "DONE"

echo -n "i> Copying documentation files ....................... "
_chgLog="ChangeLog-${TTYLINUX_PLATFORM}"
cp ${TTYLINUX_DOC_DIR}/${_chgLog}      cdrom/doc/
cp ${TTYLINUX_DOC_DIR}/User_Guide.html cdrom/doc/
cp ${TTYLINUX_DOC_DIR}/User_Guide.pdf  cdrom/doc/
cp ${TTYLINUX_DOC_DIR}/User_Guide.tex  cdrom/doc/
unset _chgLog
chmod 644 cdrom/doc/*
echo "DONE"

echo -n "i> Copying packages .................................. "
cp ${TTYLINUX_PKGBIN_DIR}/* cdrom/packages/
echo "DONE"

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

echo "##### START cross-building the distribution directory"
echo ""

[[ "${TTYLINUX_PLATFORM}" == "beagle_bone"   ]] && bbone_dir_make   || true
[[ "${TTYLINUX_PLATFORM}" == "mac_g4"        ]] && mac_dir_make     || true
[[ "${TTYLINUX_PLATFORM}" == "pc_i486"       ]] && pc_dir_make      || true
[[ "${TTYLINUX_PLATFORM}" == "pc_i686"       ]] && pc_dir_make      || true
[[ "${TTYLINUX_PLATFORM}" == "pc_x86_64"     ]] && pc_dir_make      || true
[[ "${TTYLINUX_PLATFORM}" == "wrtu54g_tm"    ]] && wrtu54g_dir_make || true

echo ""
echo "##### DONE cross-building the distribution directory"


# *****************************************************************************
# Exit OK
# *****************************************************************************

exit 0


# end of file
