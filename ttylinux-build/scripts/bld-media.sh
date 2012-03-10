#!/bin/bash


# This file is part of the ttylinux software.
# The license which this software falls under is GPLv2 as follows:
#
# Copyright (C) 2008-2011 Douglas Jerome <douglas@ttylinux.org>
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
#	This script invokes the platform-specific script that puts the ttylinux
#	bootable files onto appropriate media.
#
# CHANGE LOG
#
#	04mar11	drj	File creation.
#
# *****************************************************************************


# *************************************************************************** #
#                                                                             #
# S U B R O U T I N E S                                                       #
#                                                                             #
# *************************************************************************** #


# *****************************************************************************
# Write Boot Files to an SD Card for BeagleBone
# *****************************************************************************

package_installer() {

local pkgSrcDir=$1
local destDir=$2
local shareDir="${destDir}/usr/share/ttylinux"
local pkglst=""
local pkg=""

rm --force TIME_STAMP
>TIME_STAMP

for pkg in $(ls ${pkgSrcDir}); do
        if [[ x"${pkg:0:16}" == x"ttylinux-basefs-" ]]; then
                pkglst="${pkg} ${pkglst}"
        else
                pkglst="${pkglst} ${pkg}"
        fi
done

mkdir -p "${shareDir}"
for pkg in ${pkglst}; do
        echo "=> ${pkg}"
	_tfile="${pkgSrcDir}/${pkg}"
	pkg="${pkg%-${TTYLINUX_CPU}.tbz}"
        tar --extract --file="${_tfile}" --directory="${destDir}"
        if [[ x"${pkg#*-}" != x"nopackage" ]]; then
                tar --list --file="${_tfile}" >"${shareDir}/pkg-${pkg}-FILES"
        fi
	unset _tfile
done

echo -n "Updating birthdays ... "
find "${destDir}" -type d -o -type f -exec touch --reference=TIME_STAMP {} \;
echo "DONE"

rm --force TIME_STAMP

}

# *****************************************************************************

sdcard_bbone_make() {

local sdCardDev=""
local bd=0
local _t1=""
local _t2=""
local _t3=""
local _t4=""

echo "i> Looking for ttylinux BeagleBone SD card."

set +o errexit # # Do not exit on command error.  Let mount and umount fail.
for (( bd=0 ; ${bd} < 8 ; bd=$((${bd} + 1)) )); do
	_t1=$(blkid -s TYPE /dev/mmcblk${bd}p1)
	_t2=$(blkid -s TYPE /dev/mmcblk${bd}p2)
	_t3=$(blkid -s TYPE /dev/mmcblk${bd}p3)
	_t4=$(blkid -s TYPE /dev/mmcblk${bd}p4)
	_t1=$(expr "${_t1}" : ".*=\"\(.*\)\"")
	_t2=$(expr "${_t2}" : ".*=\"\(.*\)\"")
	_t3=$(expr "${_t3}" : ".*=\"\(.*\)\"")
	_t4=$(expr "${_t4}" : ".*=\"\(.*\)\"")
	echo "=> checking /dev/mmcblk${bd} [p1=${_t1}, p2=${_t2}, p3=${_t3}, p4=${_t4}]"
	[[ "${_t1}" != "vfat" ]] && continue
	[[ "${_t2}" != "ext4" ]] && continue
	[[ "${_t3}" != "ext4" ]] && continue
	[[ "${_t4}" != "swap" ]] && continue
	sdCardDev="/dev/mmcblk${bd}"
	bd=8
done
set -o errexit # # Exit on command error.

if [[ -z "${sdCardDev}" ]]; then
	echo "E> Cannot find an appropriate SD card paritition."
	return 0
fi

echo ""
echo "Using: ${sdCardDev}"

pushd "${TTYLINUX_BUILD_DIR}" >/dev/null 2>&1

umount "${sdCardDev}p1" >/dev/null 2>&1
umount "${sdCardDev}p2" >/dev/null 2>&1
umount "${sdCardDev}p3" >/dev/null 2>&1
umount "${sdCardDev}p4" >/dev/null 2>&1

# Setup Boot Partition

echo ""
echo "i> Setup BOOT Partition [${sdCardDev}p1]"

echo -n "=> Formatting partition [fat32] ............ "
mkfs.vfat -F 16 -n boot "${sdCardDev}p1" >/dev/null 2>&1
echo "DONE"

echo -n "=> Mounting the partition .................. "
mount -t vfat "${sdCardDev}p1" ${TTYLINUX_MNT_DIR} >/dev/null 2>&1
echo "DONE"

echo -n "=> Copying the boot files to the media ..... "
cp sdcard/boot/MLO        ${TTYLINUX_MNT_DIR}/MLO
cp sdcard/boot/u-boot.img ${TTYLINUX_MNT_DIR}/u-boot.img
cp sdcard/boot/uEnv.txt   ${TTYLINUX_MNT_DIR}/uEnv.txt
cp sdcard/boot/uImage     ${TTYLINUX_MNT_DIR}/uImage
cp sdcard/boot/vmlinux    ${TTYLINUX_MNT_DIR}/vmlinux
cp sdcard/boot/System.map ${TTYLINUX_MNT_DIR}/System.map
echo "DONE"
echo -n "File listing:"
ls --color -hil ${TTYLINUX_MNT_DIR} | sort | grep -v "^ *$"

echo -n "=> Unmounting the partition ................ "
umount "${sdCardDev}p1"
echo "DONE"

# Setup File Systems Partitions

echo ""
echo "i> Setup ROOTFS partition [${sdCardDev}p2]."

echo -n "=> Formatting partition [ext4] ............. "
mkfs.ext4 -j -L rootfs "${sdCardDev}p2" >/dev/null 2>&1
echo "DONE"

echo -n "=> Mounting the / partition ................ "
mount -t ext4 "${sdCardDev}p2" "${TTYLINUX_MNT_DIR}" >/dev/null 2>&1
echo "DONE"

echo ""
echo "i> Setup VARFS partition [${sdCardDev}p3]."

echo -n "=> Formatting partition [ext4] ........... "
mkfs.ext4 -j -L varfs "${sdCardDev}p3" >/dev/null 2>&1
echo "DONE"

echo -n "=> Mounting the /var partition ............. "
mkdir "${TTYLINUX_MNT_DIR}/var"
mount -t ext4 "${sdCardDev}p3" "${TTYLINUX_MNT_DIR}/var" >/dev/null 2>&1
echo "DONE"

echo "** Start installing packages."
package_installer "sdcard/packages" "${TTYLINUX_MNT_DIR}"
echo "** Done installing packages."

echo -n "=> Fix file system for persistent boot ..... "
l1="/dev/mmcblk0p2 /        ext4     defaults                    0 0"
l2="/dev/mmcblk0p3 /var     ext4     defaults                    0 0"
sed --in-place \
	--expression="s#/dev/ram0.*#${l1}\n${l2}#" \
	"${TTYLINUX_MNT_DIR}/etc/fstab"
unset l1
unset l2
echo "DONE"

echo -n "=> File system usage: "
du -sh ${TTYLINUX_MNT_DIR} | awk '{print $1}'

echo -n "=> Unmounting the file system partitions ... "
umount "${sdCardDev}p3"
umount "${sdCardDev}p2"
echo "DONE"

# Setup Swap Partition

echo ""
echo "i> Setup SWAP partition [${sdCardDev}p4]."

echo -n "=> Formatting swap partition ............... "
mkswap -L swap "${sdCardDev}p4" >/dev/null 2>&1
echo "DONE"

popd >/dev/null 2>&1

return 0

}


# *****************************************************************************
# Nada
# *****************************************************************************

nada() {

echo "i> No media method for ${TTYLINUX_PLATFORM}."
return 0

}


# *****************************************************************************
# Write Boot Files to an CD-ROM
# *****************************************************************************

cd_burn() {

echo ""
cdrecord -v speed=44 dev=1,0,0 -tao -data ${TTYLINUX_ISO_NAME}
echo ""

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


# *****************************************************************************
# Main Program
# *****************************************************************************

echo ""
echo "##### START making the boot file system image"
echo ""

[[ "${TTYLINUX_PLATFORM}" == "beagle_bone"   ]] && sdcard_bbone_make   || true
[[ "${TTYLINUX_PLATFORM}" == "mac_g4"        ]] && cd_burn             || true
[[ "${TTYLINUX_PLATFORM}" == "pc_i486"       ]] && cd_burn             || true
[[ "${TTYLINUX_PLATFORM}" == "pc_i686"       ]] && cd_burn             || true
[[ "${TTYLINUX_PLATFORM}" == "pc_x86_64"     ]] && cd_burn             || true
[[ "${TTYLINUX_PLATFORM}" == "wrtu54g_tm"    ]] && nada                || true

echo ""
echo "##### DONE making the boot file system image"
echo ""


# *****************************************************************************
# Exit OK
# *****************************************************************************

exit 0


# end of file
