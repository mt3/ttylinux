#!/bin/bash


# This file is part of the ttylinux software.
# The license which this software falls under is GPLv2 as follows:
#
# Copyright (C) 2012-2012 Douglas Jerome <douglas@ttylinux.org>
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
#	This script invokes the platform-specific script that formats the
#       ttylinux bootable media.
#
# CHANGE LOG
#
#	19feb12	drj	Changes for build process reorganization.
#	02feb12	drj	File creation.
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

bbone_sdcard_format() {

local sdCardDev=""
local bd=0
local _nbytes=0

echo "i> Looking for SD card."

set +o errexit # # Do not exit on command error.  Let mount and umount fail.
for (( bd=0 ; ${bd} < 8 ; bd=$((${bd} + 1)) )); do
	echo "=> checking /dev/mmcblk${bd}"
	if [[ -b "/dev/mmcblk${bd}" ]]; then
		sdCardDev="/dev/mmcblk${bd}"
		bd=8
	fi
done
set -o errexit # # Exit on command error.

if [[ -z "${sdCardDev}" ]]; then
	echo "E> Cannot find an appropriate SD card paritition."
	return 0
fi

read -p "Format ${sdCardDev} for BeagleBone ttylinux? [y|n] >"
if [[ x"${REPLY}" != x"y" ]]; then
	echo "E> Did not reply with \"y\".  Aborting."
	return 0
fi

echo ""
echo "Using: ${sdCardDev}"

umount "${sdCardDev}p1" >/dev/null 2>&1
umount "${sdCardDev}p2" >/dev/null 2>&1
umount "${sdCardDev}p3" >/dev/null 2>&1
umount "${sdCardDev}p4" >/dev/null 2>&1
umount "${sdCardDev}p5" >/dev/null 2>&1
umount "${sdCardDev}p6" >/dev/null 2>&1
umount "${sdCardDev}p7" >/dev/null 2>&1
umount "${sdCardDev}p8" >/dev/null 2>&1

# Whack the everything.
#
echo "=> Whacking the everything."
dd if=/dev/zero of=${sdCardDev} bs=1M count=1 >/dev/null 2>&1

# Get the number of bytes in the media and calculate the number of
# 255*63*512 byte cylinders.
# Each cylinder has 255 * 63 * 512 = 8,225,280 bytes.
#
_nbytes=`fdisk -l ${sdCardDev} 2>/dev/null | grep Disk | awk '{print $5}'`
_gbytes=$(((${_nbytes} / 1024 / 1024 / 1024) + 1))
_ncyls=$((${_nbytes} / 255 / 63 / 512))

echo -n "=> Auto-partitioning ................................. "
# ${sdCardDev}p1 has Cyl Count (9) for    64 MB - FAT boot
# ${sdCardDev}p2 has remaining Cyl Count xxx MB - ext4 /
# ${sdCardDev}p3 has Cyl Count (33) for  256 MB - ext4 /var
# ${sdCardDev}p4 has Cyl Count (33) for  256 MB - swap
#
rfs=$((${_ncyls} - 9 - 33 - 33))
#
{
echo ,9,b,*
echo ,${rfs},L,-
echo ,33,L,-
echo ,33,S,-
echo ;
} | sfdisk -D -H 255 -S 63 -C ${_ncyls} ${sdCardDev} >/dev/null 2>&1
echo "DONE"

umount "${sdCardDev}p1" >/dev/null 2>&1
umount "${sdCardDev}p2" >/dev/null 2>&1
umount "${sdCardDev}p3" >/dev/null 2>&1
umount "${sdCardDev}p4" >/dev/null 2>&1

fdisk -l "${sdCardDev}" | sed -e "s#swap / Solaris#Swap#"
echo ""

echo -n "=> Formatting FAT 16 boot partition ${sdCardDev}p1 ... "
mkfs.vfat -F 16 -n boot "${sdCardDev}p1" >/dev/null 2>&1
echo "DONE"

echo -n "=> Formatting ext4 root partition ${sdCardDev}p2 ..... "
mkfs.ext4 -L rootfs "${sdCardDev}p2" >/dev/null 2>&1
echo "DONE"

echo -n "=> Formatting ext4 root partition ${sdCardDev}p2 ..... "
mkfs.ext4 -L varfs "${sdCardDev}p3" >/dev/null 2>&1
echo "DONE"

echo -n "=> Formatting swap partition ${sdCardDev}p2 .......... "
mkswap -L swap "${sdCardDev}p4" >/dev/null 2>&1
echo "DONE"

return 0

}


# *****************************************************************************
# Nada
# *****************************************************************************

nada() {

echo "i> No media format method for ${TTYLINUX_PLATFORM}."
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


# *****************************************************************************
# Main Program
# *****************************************************************************

echo ""
echo "##### START formatting the boot media"
echo ""

[[ "${TTYLINUX_PLATFORM}" == "beagle_bone"   ]] && bbone_sdcard_format || true
[[ "${TTYLINUX_PLATFORM}" == "mac_g4"        ]] && nada                || true
[[ "${TTYLINUX_PLATFORM}" == "pc_i486"       ]] && nada                || true
[[ "${TTYLINUX_PLATFORM}" == "pc_i686"       ]] && nada                || true
[[ "${TTYLINUX_PLATFORM}" == "pc_x86_64"     ]] && nada                || true
[[ "${TTYLINUX_PLATFORM}" == "wrtu54g_tm"    ]] && nada                || true

echo ""
echo "##### DONE formatting the boot media"
echo ""


# *****************************************************************************
# Exit OK
# *****************************************************************************

exit 0


# end of file
