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


# *****************************************************************************
#
# PROGRAM DESCRIPTION
#
#	This script runs the Linux kernel configuration process for the
#	ttylinux kernel using the existing ttylinux configuration.  The new
#	configuration file is put in the top-level ttylinux directory.
#
# CHANGE LOG
#
#	19feb12	drj	Changed for build system reorganization.
#	12feb12	drj	Changed kernel source location.
#	14mar11	drj	Put kernel config file in top-level ttylinux directory.
#	16feb11	drj	Put kernel config file in config/platform directory.
#	01jan11	drj	Added TTYLINUX_CLASS to kernel configuration file name.
#	22dec10	drj	Change build directory to temporary directory in var.
#	11dec10	drj	Removed alternate linux kernel location.
#	11dec10	drj	Use the new platform directory structure.
#	13nov10	drj	Minor fixups.
#	09oct10	drj	Minor simplifications.
#	09apr10	drj	File creation.
#
# *****************************************************************************


# *************************************************************************** #
#                                                                             #
# S U B R O U T I N E S                                                       #
#                                                                             #
# *************************************************************************** #


# *****************************************************************************
# Try to clean up.
# *****************************************************************************

bail_out() {

rm --force --recursive ${K_BLD_DIR}

}


# *****************************************************************************
# Configure a Linux kernel.
# *****************************************************************************

kernel_config() {

local kver=${XBT_LINUX_VER##*-}
local kname="kernel-${kver}"
local kcfg="${TTYLINUX_PLATFORM_DIR}/${kname}.cfg"
local srcd="${TTYLINUX_XTOOL_DIR}/_pkg-src"

echo "i> Regenerate a Linux configuration file:"
echo "=> ${TTYLINUX_TARGET_TAG}"
echo "=> ${kname}.cfg"

# Look for the linux kernel tarball.
#
if [[ ! -f "${srcd}/linux-${kver}.tar.bz2" ]]; then
	echo "E> Linux kernel source tarball not found." >&2
	echo "=> ${srcd}/linux-${kver}.tar.bz2" >&2
	exit 1
fi

# Look for the linux kernel configuration file.
#
if [[ ! -f "${kcfg}" ]]; then
	echo "w> Linux kernel configuration file not found." >&2
	echo "=> ${kcfg}" >&2
	: # ?? exit 1
fi

trap bail_out EXIT

# Uncompress, untarr then remove linux-${kver}.tar.bz2.
#
echo -n "i> Getting and uncompressing linux-${kver}.tar.bz2 ... "
rm --force --recursive linux-${kver}*
cp "${srcd}/linux-${kver}.tar.bz2" "linux-${kver}.tar.bz2"
bunzip2 --force "linux-${kver}.tar.bz2"
tar --extract --file="linux-${kver}.tar"
rm --force "linux-${kver}.tar"
echo "DONE"

# Make a kernel configuration, starting with the current configuration if there
# is one.
#
echo ""
echo "Save your kernel configuration file as \".config\" and it will be"
echo "renamed and copied to the ttylinux directory:"
echo "=> ${TTYLINUX_DIR}"
echo ""
echo "i> make menuconfig ARCH=${XBT_LINUX_ARCH} KCONFIG_CONFIG=.config"
echo -n "Hit <enter> to continue: "
read
[[ -f "${kcfg}" ]] && cp "${kcfg}" "linux-${kver}/.config" || true
cd "linux-${kver}"
sed --in-place scripts/unifdef.c --expression="s/getline/uc_&/"
sed --in-place scripts/mod/sumversion.c \
	--expression="s|<string.h>| <limits.h>\n#include <string.h>|"
_tarFile="${TTYLINUX_PLATFORM_DIR}/${kname}-add_in.tar.bz2"
if [[ -f ${_tarFile} ]]; then
	echo "Adding-in ${kname}-add_in.tar.bz2"
	tar --extract --file="${_tarFile}"
fi
unset _tarFile
for p in "${TTYLINUX_PLATFORM_DIR}/${kname}-??.patch"; do
	if [[ -f "${p}" ]]; then
		echo "=> patching with $(basename ${p})"
		patch -p1 <${p} >/dev/null
	fi
done
TERM=xterm-color make menuconfig ARCH=${XBT_LINUX_ARCH} KCONFIG_CONFIG=.config
cd ..

# If there is a new configuration file with the standard name, then move an
# old kernel configuration file to a backup and then move the new configuration
# file into its place.
#
if [[ -f "linux-${kver}/.config" ]]; then
	newCfgFile="${TTYLINUX_DIR}/${kname}.cfg"
	if [[ -f "${newCfgFile}"  ]]; then
		fver="00"
		oldCfgFile="${TTYLINUX_DIR}/${kname}-${fver}.cfg"
		while [[ -f "${oldCfgFile}"  ]]; do
			fver=$((${fver} + 1))
			[[ ${fver} -lt 10 ]] && fver="0${fver}" || true
			oldCfgFile="${TTYLINUX_DIR}/${kname}-${fver}.cfg"
		done
		echo -e "i> Making backup of kernel config file."
		echo -e "=> was: ${newCfgFile}"
		echo -e "=> now: ${oldCfgFile}"
		mv "${newCfgFile}" "${oldCfgFile}"
		unset fver
		unset oldCfgFile
	fi
	mv "linux-${kver}/.config" "${newCfgFile}"
	chmod 600 "${newCfgFile}"
	echo ""
	echo -e "i> New kernel config file is ready."
	echo -e "=> ${TEXT_BGREEN}${newCfgFile}${TEXT_NORM}"
	echo ""
	echo -e "To use the new kernel configuration file, copy it to the"
	echo -e "platform directory:"
	echo -e "=> ${TTYLINUX_PLATFORM_DIR}"
	echo ""
	unset newCfgFile
fi

trap - EXIT

rm --force --recursive ${K_BLD_DIR}

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

dist_config_setup  || exit 1
build_config_setup || exit 1


# *****************************************************************************
# Main Program
# *****************************************************************************

K_BLD_DIR=$(mktemp --directory ${TTYLINUX_VAR_DIR}/tmp.XXXXXXXX 2>/dev/null)
if [[ $? != 0 ]]; then
	echo "E> Cannot make temporary directory." >&2
	echo "=> Maybe install mktemp" >&2
	exit 1
fi

pushd "${K_BLD_DIR}" >/dev/null 2>&1
kernel_config
popd >/dev/null 2>&1

unset K_BLD_DIR

echo ""
echo "##### DONE cross-configuring a kernel config file."


# *****************************************************************************
# Exit OK
# *****************************************************************************

exit 0


# end of file
