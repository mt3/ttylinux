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
#	This script makes the ttylinux kernel.
#
# CHANGE LOG
#
#	16mar12	drj	Added more elaborate logging of comments and commands.
#	08mar12	drj	Better setting njobs.
#	18feb12	drj	Rewrite for build process reorganization.
#	11feb12	drj	Avoid patching a user-custom ttylinux kernel.
#	11feb12	drj	Fixed source location.  Removed old targets.
#	29jan12	drj	Added BeagleBone kernel build target.
#	15mar11	drj	Added BeagleBoard xM kernel build target.
#	12feb11	drj	Added kernel version to the kmodule package file name.
#	01jan11	drj	Added TTYLINUX_CLASS to kernel configuration file name.
#	22dec10	drj	Added support for building mips kernels.
#	15dec10	drj	Use new kernel module package file name and location.
#	11dec10	drj	Changed for the new platform directory structure.
#	16nov10	drj	Added kernel module building.
#	15nov10	drj	Added fixup for the getline() in scripts/unifdef.c
#	13nov10	drj	Removed all RTAI support.
#	09oct10	drj	Minor simplifications.
#	22aug10	drj	Added RTAI kernel patch suport.
#	27jul10	drj	Fixed the TTYLINUX_KERNEL usage in kernel_xbuild().
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
# Try to clean up.
# *****************************************************************************

kernel_clean() {

local kver=${TTYLINUX_USER_KERNEL:-${XBT_LINUX_VER##*-}}

ttylinux_build_comment ""
ttylinux_build_comment "remove build/kpkgs"
ttylinux_build_comment "remove build/kroot"
ttylinux_build_comment "remove build/linux-<vers>"
ttylinux_build_comment ""

rm --force --recursive "${TTYLINUX_BUILD_DIR}"/kpkgs/*
rm --force --recursive "${TTYLINUX_BUILD_DIR}"/kroot/*
rm --force --recursive "${TTYLINUX_BUILD_DIR}"/linux-${kver}*/
rm --force --recursive "${TTYLINUX_BUILD_DIR}"/linux/

}


# *****************************************************************************
# Get the kernel source tree and configuration file.
# *****************************************************************************

kernel_get() {

local kver="${TTYLINUX_USER_KERNEL:-${XBT_LINUX_VER##*-}}"
local kcfg="${TTYLINUX_PLATFORM_DIR}/kernel-${kver}.cfg"
local srcd="${TTYLINUX_XTOOL_DIR}/_pkg-src"

echo -n "g." >&${CONSOLE_FD}

# If TTYLINUX_USER_KERNEL is set then there is a user-custom kernel to build,
# in which case the linux source and kernel configuration files are supposed
# to be in the site/platform-${TTYLINUX_PLATFORM} directory.
#
if [[ -n "${TTYLINUX_USER_KERNEL:-}" ]]; then
	srcd="${TTYLINUX_DIR}/site/platform-${TTYLINUX_PLATFORM}"
	kcfg="${srcd}/kernel-${TTYLINUX_USER_KERNEL}.cfg"
fi

ttylinux_build_comment ""
ttylinux_build_comment "kernel source"
ttylinux_build_comment "=> ${srcd}/linux-${kver}.tar.bz2"

# Look for the linux kernel tarball.
#
if [[ ! -f "${srcd}/linux-${kver}.tar.bz2" ]]; then
	echo "E> Linux kernel source tarball not found." >&2
	echo "=> ${srcd}/linux-${kver}.tar.bz2" >&2
	exit 1
fi

ttylinux_build_comment ""
ttylinux_build_comment "kernel config"
ttylinux_build_comment "=> ${kcfg}"

# Look for the linux kernel configuration file.
#
if [[ ! -f "${kcfg}" ]]; then
	echo "E> Linux kernel configuration file not found." >&2
	echo "=> ${kcfg}" >&2
	exit 1
fi

_modules=$(set +u; source ${kcfg}; echo "${CONFIG_MODULES}")
[[ x"${_modules}" == x"y" ]] && K_MODULES="yes"
unset _modules
if [[ "${K_MODULES}" == "yes" ]]; then
	ttylinux_build_comment ""
	ttylinux_build_comment "This kernel configuration has modules."
else
	ttylinux_build_comment ""
	ttylinux_build_comment "This kernel configuration has NO modules."
fi

# Cleanup any pervious, left-over build results.
#
kernel_clean

# Uncompress, untarr then remove linux-${kver}.tar.bz2 and put the kernel
# configuration file in place.
#
# trap kernel_clean EXIT
#
ttylinux_build_comment ""
ttylinux_build_command "cp ${srcd}/linux-${kver}.tar.bz2 linux-${kver}.tar.bz2"
ttylinux_build_command "bunzip2 --force linux-${kver}.tar.bz2"
ttylinux_build_command "tar --extract --file=linux-${kver}.tar"
ttylinux_build_command "rm --force linux-${kver}.tar"
ttylinux_build_command "cp ${kcfg} linux-${kver}/.config"
#
trap - EXIT

}


# *****************************************************************************
# Build the kernel from source and make a binary package.
# *****************************************************************************

kernel_xbuild() {

local kver="${TTYLINUX_USER_KERNEL:-${XBT_LINUX_VER##*-}}"
local bitch=""
local target=""

echo -n "b." >&${CONSOLE_FD}

trap kernel_clean EXIT

# Agressively set njobs: set njobs to 2 if ${ncpus} is unset or has non-digit
# characters.
#
bitch=${ncpus:-1}
[[ -z "${bitch//[0-9]}" ]] && njobs=$((${bitch:-1} + 1)) || njobs=2

# Set the right kernel make target.
case "${TTYLINUX_PLATFORM}" in
	beagle_*)   target="uImage"  ;;
	mac_*)      target="zImage"  ;;
	pc_*)       target="bzImage" ;;
	wrtu54g_tm) target="vmlinux" ;;
esac

cd "linux-${kver}"

# If this is not a user-custom ttylinux kernel, then do some kernel source code
# fix-ups, if needed.
#
if [[ -z "${TTYLINUX_USER_KERNEL:-}" ]]; then
	if [[ -f scripts/unifdef.c ]]; then
		# This is for older kernels; it is harmless otherwise.
		_cmd="sed -e \"s/getline/uc_&/\" -i scripts/unifdef.c"
		ttylinux_build_comment ""
		ttylinux_build_command "${_cmd}"
		unset _cmd
	fi
	if [[ -f scripts/mod/sumversion.c ]]; then
		# This is for older kernels; it is harmless otherwise.
		_old="<string.h>"
		_new="<limits.h>\n#include <string.h>"
		_cmd="sed -e \"s|${_old}|${_new}|\" -i scripts/mod/sumversion.c"
		ttylinux_build_comment ""
		ttylinux_build_command "${_cmd}"
		unset _old
		unset _new
		unset _cmd
	fi
	_tarFile="${TTYLINUX_PLATFORM_DIR}/kernel-${kver}-add_in.tar.bz2"
	if [[ -f ${_tarFile} ]]; then
		_cmd="tar --extract --file=${_tarFile}"
		ttylinux_build_comment ""
		ttylinux_build_comment "Adding-in kernel-${kver}-add_in.tar.bz2"
		ttylinux_build_command "${_cmd}"
		unset _cmd
	fi
	unset _tarFile
	for p in ${TTYLINUX_PLATFORM_DIR}/kernel-${kver}-??.patch; do
		if [[ -f "${p}" ]]; then
			_cmd="patch -p1 <${p}"
			ttylinux_build_command "${_cmd}"
			unset _cmd
		fi
	done
fi

# Do the kernel cross-building.  If this kernel has modules then build them.
# Leave the kernel, system map and any kernel modules in place; get them
# later.
#
if [[ "${target}" == "uImage" ]]; then
	_xtraPath="${TTYLINUX_BOOTLOADER_DIR}/uboot"
else
	_xtraPath=""
fi
source "${TTYLINUX_XTOOL_DIR}/_xbt_env_set"
_cmd="PATH=\"${_xtraPath}:${XBT_BIN_PATH}:${PATH}\" make -j ${njobs} ${target} \
	V=1 \
	ARCH=${XBT_LINUX_ARCH} \
	CROSS_COMPILE=${XBT_TARGET}-"
ttylinux_build_comment ""
ttylinux_build_command "${_cmd}"
unset _cmd
if [[ "${K_MODULES}" == "yes" ]]; then
	_cmd="PATH=\"${XBT_BIN_PATH}:${PATH}\" make -j ${njobs} modules \
		V=1 \
		ARCH=${XBT_LINUX_ARCH} \
		CROSS_COMPILE=${XBT_TARGET}-"
	ttylinux_build_comment ""
	ttylinux_build_command "${_cmd}"
	unset _cmd
fi
source "${TTYLINUX_XTOOL_DIR}/_xbt_env_clr"
unset _xtraPath

cd ..

trap - EXIT

return 0

}


# *****************************************************************************
# Collect the built kernel into an as-built packge.
# *****************************************************************************

kernel_collect() {

local kver="${TTYLINUX_USER_KERNEL:-${XBT_LINUX_VER##*-}}"
local _vmlinuz=""

echo -n "f.m__0.p." >&${CONSOLE_FD}

# Setup kernel directories.
#
ttylinux_build_command "mkdir kroot/boot"
ttylinux_build_command "mkdir kroot/etc"
ttylinux_build_command "mkdir kroot/lib"
ttylinux_build_command "mkdir kroot/lib/modules"

# $ make vmlinux
# $ mipsel-linux-strip vmlinux
# $ echo "root=/dev/ram0 ramdisk_size=8192" >kernel.params
# $ mipsel-linux-objcopy --add-section kernparm=kernel.params vmlinux
# $ mipsel-linux-objcopy --add-section initrd=initrd.gz vmlinux

_vmlinuz="arch/${XBT_LINUX_ARCH}/boot/"
case "${TTYLINUX_PLATFORM}" in
	beagle_*)   _vmlinuz+="uImage"  ;;
	mac_*)      _vmlinuz+="zImage"  ;;
	pc_*)       _vmlinuz+="bzImage" ;;
	wrtu54g_tm) _vmlinuz="vmlinux"  ;;
esac

# Get the kernel and its system map.
#
bDir="kroot/boot"
_cmd1="cp \"linux-${kver}/System.map\"  \"${bDir}/System.map\""
_cmd2="cp \"linux-${kver}/vmlinux\"     \"${bDir}/vmlinux\""
_cmd3="cp \"linux-${kver}/${_vmlinuz}\" \"${bDir}/$(basename ${_vmlinuz})\""
ttylinux_build_command "${_cmd1}"
ttylinux_build_command "${_cmd2}"
ttylinux_build_command "${_cmd3}"
unset _cmd1
unset _cmd2
unset _cmd3
unset bDir

if [[ "${K_MODULES}" == "yes" ]]; then

	bDir="${TTYLINUX_BUILD_DIR}/kroot"
	pDir="${TTYLINUX_BUILD_DIR}/kpkgs"

	# Install the kernel modules into ${TTYLINUX_BUILD_DIR}/kroot
	#
	ttylinux_build_comment "Install the kernel modules into:"
	ttylinux_build_comment "=> ${TTYLINUX_BUILD_DIR}/kroot"
	cd "linux-${kver}"
	source "${TTYLINUX_XTOOL_DIR}/_xbt_env_set"
	_cmd="PATH=\"${XBT_BIN_PATH}:${PATH}\" make -j ${njobs} modules_install\
		V=1 \
		ARCH=${XBT_LINUX_ARCH} \
		CROSS_COMPILE=${XBT_TARGET}- \
		INSTALL_MOD_PATH=${bDir}"
	ttylinux_build_command "${_cmd}"
	unset _cmd
	source "${TTYLINUX_XTOOL_DIR}/_xbt_env_clr"
	cd ..

	# Scrub the modules directory.
	#
	ttylinux_build_comment "Scrub the modules directory; remove these:"
	ttylinux_build_comment "=> ${bDir}/lib/modules/${kver}/build"
	ttylinux_build_comment "=> ${bDir}/lib/modules/${kver}/source"
	rm --force "${bDir}/lib/modules/${kver}/build"
	rm --force "${bDir}/lib/modules/${kver}/source"

	# Make the kernel modules binary package in ${TTYLINUX_BUILD_DIR}/kpkgs
	#
	uTarBall="${pDir}/kmodules-${kver}-${TTYLINUX_CPU}.tar"
	cTarBall="${pDir}/kmodules-${kver}-${TTYLINUX_CPU}.tbz"
	_cmd1="tar --directory ${bDir} --create --file=\"${uTarBall}\" lib"
	_cmd2="bzip2 --force \"${uTarBall}\""
	_cmd3="mv --force \"${uTarBall}.bz2\" \"${cTarBall}\""
	_cmd4="cp \"${cTarBall}\" \"${TTYLINUX_PKGBIN_DIR}\""
	ttylinux_build_command "${_cmd1}"
	ttylinux_build_command "${_cmd2}"
	ttylinux_build_command "${_cmd3}"
	ttylinux_build_command "${_cmd4}"
	unset _cmd1
	unset _cmd2
	unset _cmd3
	unset _cmd4
	unset uTarBall
	unset cTarBall

	unset bDir
	unset pDir

fi

echo -n "c" >&${CONSOLE_FD}
echo "i> Removing build directory linux-${kver}"
rm --force --recursive "linux-${kver}/"
rm --force --recursive "linux/"

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

K_MODULES="no"

source ./ttylinux-config.sh    # target build configuration
source ./scripts/_functions.sh # build support

dist_root_check    || exit 1
dist_config_setup  || exit 1
build_config_setup || exit 1
build_spec_show    || exit 1

if [[ ! -d "${TTYLINUX_BUILD_DIR}" ]]; then
	echo "E> The build directory does NOT exist." >&2
	echo "E>      ${TTYLINUX_BUILD_DIR}" >&2
	exit 1
fi


# *****************************************************************************
# Main Program
# *****************************************************************************

echo ""
echo "##### START cross-building the kernel"
echo "g - getting the source and configuration packages"
echo "b - building and installing the package into build-root"
echo "f - finding installed files"
echo "m - looking for man pages to compress"
echo "p - creating installable package"
echo "c - cleaning"
echo ""

pushd "${TTYLINUX_BUILD_DIR}" >/dev/null 2>&1

pname="linux-${TTYLINUX_USER_KERNEL:-${XBT_LINUX_VER##*-}}"

t1=${SECONDS}
echo -n "${TTYLINUX_CPU} ${pname} ";
for ((i=(20-${#pname}) ; i > 0 ; i--)); do echo -n "."; done
echo -n " ";

exec 4>&1    # Save stdout at fd 4.
CONSOLE_FD=4 #

rm --force "${TTYLINUX_VAR_DIR}/log/${pname}.log"
kernel_get     >>"${TTYLINUX_VAR_DIR}/log/${pname}.log" 2>&1
kernel_xbuild  >>"${TTYLINUX_VAR_DIR}/log/${pname}.log" 2>&1
kernel_collect >>"${TTYLINUX_VAR_DIR}/log/${pname}.log" 2>&1

exec >&4     # Set fd 1 back to stdout.
CONSOLE_FD=1 #

echo -n " ... DONE ["
t2=${SECONDS}
mins=$(((${t2}-${t1})/60))
secs=$(((${t2}-${t1})%60))
[[ ${#mins} -eq 1 ]] && echo -n " "; echo -n "${mins} minutes "
[[ ${#secs} -eq 1 ]] && echo -n " "; echo    "${secs} seconds]"

popd >/dev/null 2>&1

echo ""
echo "##### DONE cross-building the kernel"


# *****************************************************************************
# Exit OK
# *****************************************************************************

exit 0


# end of file
