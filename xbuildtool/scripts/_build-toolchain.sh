#!/bin/bash


# This file is NOT part of the kegel-initiated cross-tools software.
# This file is NOT part of the crosstool-NG software.
# This file IS part of the ttylinux xbuildtool software.
# The license which this software falls under is GPLv2 as follows:
#
# Copyright (C) 2007-2012 Douglas Jerome <douglas@ttylinux.org>
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
#	This shell script builds a cross-development tool chain comprised of
#	Binutils, GCC, Linux kernel header files and either GLIBC or uClibc.
#
#	User configuration parameters are in the separate configuration file
#	named "xbt-build-config.sh"; this configuration file must be in the
#	top-level xbuildtool directory when building a cross-development tool
#	chain.
#
#	The proper environment needed to run this script should be acquired by
#	sourcing a correct "xbt-build-env.sh" script.  The "xbt-build-env.sh"
#	script should be in the top-level xbuildtool directory.
#
#	EXTERNAL ENVIRONMENTAL VARIABLES
#
#		The configurations files "xbt-build-config.sh" and
#		"xbt-build-env.sh" supply the external environmental variables
#		needed to run this script.  These variables are no longer
#		listed here.
#
# CHANGE LOG
#
#	18mar12	drj	Track the failed package downloads and report on them.
#	14mar12	drj	Made a better ncpus setting.
#	24feb12	drj	Remove <path>/.. from CROSS_TOOL_DIR.
#	19feb12	drj	Added text manifest of tool chain components.
#	10feb12	drj	Added the making of GCC libraries.
#	09feb12	drj	Added XBT_XSRC_DIR.
#	31jan11	drj	Moved libgcc_s.* from usr/lib to lib.
#	01jan11	drj	Re-wrote ttylinux cross-tools "generic-linux-gnu.sh".
#
# *****************************************************************************


# *************************************************************************** #
#                                                                             #
# G L O B A L   D A T A                                                       #
#                                                                             #
# *************************************************************************** #

G_MISSED_PKG[0]=""
G_MISSED_URL[0]=""
G_NMISSING=0


# *************************************************************************** #
# S U B R O U T I N E S                                                       #
#                                                                             #
# *************************************************************************** #


# *****************************************************************************
# xbt_debug_break
# *****************************************************************************

xbt_debug_break() {

if [[ x"${XBT_DEBUG:-no}" = x"yes" ]]; then
	local prompt="${1:0:40}" # No more than 40 characters.
	if [[ -z "${prompt}" ]]; then
		echo "" >&${CONSOLE_FD}
	else
		printf "** %40s ->" "${prompt}" >&${CONSOLE_FD}
		read
	fi
fi

}


# *****************************************************************************
# xbt_get_file
# *****************************************************************************

# Usage: xbt_get_file <filename> <url> [url ...]

xbt_get_file() {

local fileName=""
local haveFile="no"
local loadedDn="no"
local ext
local url

[[ -z "${1}" ]] && return 0 || true

fileName="$1"

shift # Go to the urls.

pushd "${XBT_SOURCE_DIR}" >/dev/null 2>&1

echo -n "i> Checking ${fileName} "
for ((i=(21-${#fileName}) ; i > 0 ; i--)); do echo -n "."; done

rm -f "${fileName}.download.log"

# If the file is already in ${XBT_SOURCE_DIR} then return.
#
for ext in ${K_EXT}; do
	[[ -f "${fileName}${ext}" ]] && haveFile="yes" || true
done
if [[ "${haveFile}" = "yes" ]]; then
	echo " have it."
	popd >/dev/null 2>&1
	return 0
fi

echo -n " downloading ..... "

# See if there is a local copy of the file.
#
for ext in ${K_EXT}; do
	if [[ -f ${K_CACHEDIR}/${fileName}${ext} ]]; then
		cp ${K_CACHEDIR}/${fileName}${ext} .
		[[ -f "${fileName}${ext}" ]] && loadedDn="yes" || true
	fi
done
if [[ "${loadedDn}" = "yes" ]]; then
	echo "(got from local cache)"
	popd >/dev/null 2>&1
	return 0
fi

# See if there is a program to use to download the file.
#
_wget=$(which wget 2>/dev/null || true)
if [[ -z "${_wget}" ]]; then
	echo "cannot find wget-- no download."
	popd >/dev/null 2>&1
	unset _wget
	return 0
fi
_wget="${_wget} -T 10 -nc --progress=dot:binary --tries=3"
_file=""

# Try to download the file from the urls.
#
rm -f "${fileName}.download.log"
>"${fileName}.download.log"
for ext in ${K_EXT}; do
	for url in "$@"; do
		_file="${url}/${fileName}${ext}"
		if [[ "${loadedDn}" = "no" ]]; then
			(${_wget} --passive-ftp "${_file}" \
			|| ${_wget} "${_file}" \
			|| true) >>"${fileName}.download.log" 2>&1
			[[ -f "${fileName}${ext}" ]] && loadedDn="yes" || true
		fi
	done
done 
unset _wget
unset _file

if [[ "${loadedDn}" = "yes" ]]; then
	echo "done."
	rm -f "${fileName}.download.log"
else
	echo "FAILED."
	G_MISSED_PKG[${G_NMISSING}]="${fileName}${ext}"
	G_MISSED_URL[${G_NMISSING}]="${url}"
	G_NMISSING=$((${G_NMISSING} + 1))
fi

popd >/dev/null 2>&1
return 0

}


# *****************************************************************************
# xbt_chk_file
# *****************************************************************************

# Usage: xbt_chk_file <filename> <md5sum>

xbt_chk_file() {

local fileName=""
local fileCsum=""
local loadedDn="no"
local chksum
local ext

[[ -z "${1}" ]] && return 0 || true

fileName="$1"
fileCsum="$2"

pushd "${XBT_SOURCE_DIR}" >/dev/null 2>&1

# If the file is missing then report and quit. The found file name is
# stored in ${loadedDn}
#
for ext in ${K_EXT}; do
	[[ -f "${fileName}${ext}" ]] && loadedDn="${fileName}${ext}" || true
done
if [[ "${loadedDn}" = "no" ]]; then
	echo "E> Missing ${fileName} file."
	popd >/dev/null 2>&1
	return 0
fi

# See if there ia an expected md5sum to check against.
#
if [[ -z "${fileCsum}" ]]; then
	echo "w> No expected md5sum for ${fileName} file."
	popd >/dev/null 2>&1
	return 0
fi

# Check the md5sum and report.
#
echo -n "=> md5sum ${loadedDn} "
for ((i=(26-${#loadedDn}) ; i > 0 ; i--)); do echo -n "."; done
chksum=$(md5sum ${loadedDn} | awk '{print $1;}')
if [[ "${chksum}" = "${fileCsum}" ]]; then
	echo " OK (${chksum})"
else
	echo " MISMATCH"
	echo "=> expected ..... ${fileCsum}"
	echo "=> calculated ... ${chksum}"
	K_ERR=1
fi

popd >/dev/null 2>&1
return 0

}


# *****************************************************************************
# Copy GCC target components into the target directory.
# *****************************************************************************

xbt_target_adjust() {

echo "=> Adjusting cross-tool chain." >&${CONSOLE_FD}

# Setup source and destination directory paths variables.
#
src="${XBT_XHOST_DIR}/usr/${XBT_TARGET}"
dst="${XBT_XTARG_DIR}"

# Create an empty header file that some packages my want to exist in order to
# compile.  There is a version of iptables that wants this.
#
if [[ -d "${XBT_XTARG_DIR}/usr/include/linux" ]]; then
	rm -f "${XBT_XTARG_DIR}/usr/include/linux/compiler.h"
	echo "/* empty */" >"${XBT_XTARG_DIR}/usr/include/linux/compiler.h"
else
	_msg="Missing ${XBT_TARGET} cross-tool host directory."
	echo "***** ${_msg}"
	echo "E> ${_msg}" >&${CONSOLE_FD}
	unset _msg
fi

# Copy the GCC target libraries.
#
if [[ -d "${src}/lib" && -d "${dst}/lib" && -d "${dst}/usr/lib" ]]; then
	cp -av ${src}/lib/libgcc_s.*  ${dst}/lib
	chmod 755 ${dst}/lib/libgcc_s.so.1
	if [[ "${XBT_C_PLUS_PLUS}" = "yes" ]]; then
		cp -av ${src}/lib/libstdc++.* ${dst}/usr/lib
		cp -av ${src}/lib/libsupc++.* ${dst}/usr/lib
	fi
	rm -fv ${dst}/usr/lib/*.la
else
	_msg="Missing ${XBT_TARGET} cross-tool host/target directory(s)."
	echo "***** ${_msg}"
	echo "E> ${_msg}" >&${CONSOLE_FD}
	unset _msg
fi

# Cleanup source and destination directory paths variables.
#
unset src
unset dst

echo "=> Completed cross-tools adjustments." >&${CONSOLE_FD}

}


# *****************************************************************************
# Cross-tool User Environment Setup
# *****************************************************************************

xbt_usr_env_set() {

echo "#!/bin/sh"
echo ""
echo "export AR=\"\""
echo "export AS=\"\""
echo "export CC=\"\""
echo "export CPP=\"\""
echo "export CXX=\"\""
echo "export LD=\"\""
echo "export MAKE=\"make \${MAKEFLAGS}\""
echo "export NM=\"\""
echo "export OBJCOPY=\"\""
echo "export RANLIB=\"\""
echo "export SIZE=\"\""
echo "export STRIP=\"\""
echo ""
echo "export ARFLAGS=\"\""
echo "export ASFLAGS=\"\""
echo "export CFLAGS=\"\""
echo "export CPPFLAGS=\"\""
echo "export CXXFLAGS=\"\""
echo "export LDFLAGS=\"\""
echo "export MAKEFLAGS=\"\""
echo ""
echo "XBT_HOST=\"${XBT_HOST}\""
echo "XBT_TARGET=\"${XBT_TARGET}\""
echo ""
echo "XBT_AR=\"${XBT_TARGET_DIR}/host/usr/bin/${XBT_TARGET}-ar\""
echo "XBT_AS=\"${XBT_TARGET_DIR}/host/usr/bin/${XBT_TARGET}-as\""
echo "XBT_CC=\"${XBT_TARGET_DIR}/host/usr/bin/${XBT_TARGET}-gcc\""
echo "XBT_CPP=\"${XBT_TARGET_DIR}/host/usr/bin/${XBT_TARGET}-cpp\""
echo "XBT_CXX=\"${XBT_TARGET_DIR}/host/usr/bin/${XBT_TARGET}-g++\""
echo "XBT_LD=\"${XBT_TARGET_DIR}/host/usr/bin/${XBT_TARGET}-ld\""
echo "XBT_NM=\"${XBT_TARGET_DIR}/host/usr/bin/${XBT_TARGET}-nm\""
echo "XBT_OBJCOPY=\"${XBT_TARGET_DIR}/host/usr/bin/${XBT_TARGET}-objcopy\""
echo "XBT_RANLIB=\"${XBT_TARGET_DIR}/host/usr/bin/${XBT_TARGET}-ranlib\""
echo "XBT_SIZE=\"${XBT_TARGET_DIR}/host/usr/bin/${XBT_TARGET}-size\""
echo "XBT_STRIP=\"${XBT_TARGET_DIR}/host/usr/bin/${XBT_TARGET}-strip\""
echo ""
echo "XBT_BIN_PATH=\"${XBT_TARGET_DIR}/host/usr/bin\""
echo ""
echo "XBT_CFLAGS=\"${XBT_CFLAGS}\""
echo "XBT_C_PLUS_PLUS=\"${XBT_C_PLUS_PLUS}\""
echo "XBT_THREAD_MODEL=\"${XBT_THREAD_MODEL}\""

}


# *****************************************************************************
# Cross-tool User Environment Clear
# *****************************************************************************

xbt_usr_env_clr() {

echo "#!/bin/sh"
echo ""
echo "export AR=\"\""
echo "export AS=\"\""
echo "export CC=\"\""
echo "export CPP=\"\""
echo "export CXX=\"\""
echo "export LD=\"\""
echo "export MAKE=\"make \${MAKEFLAGS}\""
echo "export NM=\"\""
echo "export OBJCOPY=\"\""
echo "export RANLIB=\"\""
echo "export SIZE=\"\""
echo "export STRIP=\"\""
echo ""
echo "export ARFLAGS=\"\""
echo "export ASFLAGS=\"\""
echo "export CFLAGS=\"\""
echo "export CPPFLAGS=\"\""
echo "export CXXFLAGS=\"\""
echo "export LDFLAGS=\"\""
echo "export MAKEFLAGS=\"\""

}


# *****************************************************************************
# Echo any arguments to a mapped stdout and exit with error.
# *****************************************************************************

xbt_bail() {

echo "${@}" >&${CONSOLE_FD}
exit 1

}


# *****************************************************************************
# Print No More Than 35 Dots
# *****************************************************************************

xbt_print_dots_35() {

set +e # # Let the while loop fail without exiting this script.
i=$((35 - $1))
while [[ ${i} -gt 0 ]]; do
	echo -n "."
	i=$((${i} - 1))
done
set -e # # All done with while loop.

}


# *****************************************************************************
# Get a source package; uncompress and untar it.
# *****************************************************************************

# Usage: xbt_src_get <base_filename> [<secondary_copy_location>]

xbt_src_get() {

echo "Finding, uncompressing, untarring ${1}"

local pname="${XBT_SOURCE_DIR}/${1}.tar"
local tname="${1}.tar"
local zname=""

if [[ ! -f "${pname}.gz" && ! -f "${pname}.bz2" ]]; then
	echo "Cannot find ${pname}.gz or ${pname}.bz2"
	xbt_bail "Cannot find ${pname}.gz or ${pname}.bz2"
fi
[[ -f "${pname}.gz"  ]] && zname="${tname}.gz"  || true
[[ -f "${pname}.bz2" ]] && zname="${tname}.bz2" || true
echo "Using ${XBT_SOURCE_DIR}/${zname}"
cp "${XBT_SOURCE_DIR}/${zname}" .

rm -rf "${1}"

if [[ $# -gt 1 ]]; then
	mkdir -p "$2"
	cp "${zname}" "$2"
	chmod 644 "$2/${zname}"
fi

set +e # # Let tar fail without exiting this script.
tar -xf "${zname}"
if [[ $? -ne 0 ]]; then
	bunzip2 "${zname}" || gunzip "${zname}"
	tar -xf "${tname}"
fi
set -e # # All done with tar.

if [[ ! -d ${1} ]]; then
	echo "Cannot unzip ${zname}"
	xbt_bail "Cannot unzip ${zname}"
fi

rm -f "${zname}"
rm -f "${tname}"

}


# *****************************************************************************
# Make a Timestamp File
# *****************************************************************************

xbt_files_timestamp() {

rm -rf "INSTALL_STAMP"
touch  "INSTALL_STAMP"
sleep 1 # lame

}


# *****************************************************************************
# Find Files Newer Than Timestamp File
# *****************************************************************************

xbt_files_find() {

find ${XBT_TARGET_DIR} -newer INSTALL_STAMP ! -type d
rm -rf "INSTALL_STAMP"

}


# *************************************************************************** #
#                                                                             #
# M A I N   P R O G R A M                                                     #
#                                                                             #
# *************************************************************************** #


# *****************************************************************************
# Setup Constants and Environment
# *****************************************************************************

if [[ $# -gt 0 ]]; then A_ARG1="$1"; else A_ARG1=""; fi

K_BLD_CFG_FILE="./xbt-build-config.sh"
K_BLD_ENV_FILE="./xbt-build-env.sh"
K_CACHEDIR=~/Download
K_CONSOLE_FD=1
K_ERR=0
K_EXT=".tar.bz2 .tar.gz .tgz"

TEXT_BRED="\E[1;31m"    # bold+red
TEXT_BGREEN="\E[1;32m"  # bold+green
TEXT_BYELLOW="\E[1;33m" # bold+yellow
TEXT_BBLUE="\E[1;34m"   # bold+blue
TEXT_BPURPLE="\E[1;35m" # bold+purple
TEXT_BCYAN="\E[1;36m"   # bold+cyan
TEXT_BOLD="\E[1;37m"    # bold+white
TEXT_RED="\E[0;31m"     # red
TEXT_GREEN="\E[0;32m"   # green
TEXT_YELLOW="\E[0;33m"  # yellow
TEXT_BLUE="\E[0;34m"    # blue
TEXT_PURPLE="\E[0;35m"  # purple
TEXT_CYAN="\E[0;36m"    # cyan
TEXT_NORM="\E[0;39m"    # normal

_TB=$'\t'
_NL=$'\n'
_SP=$' '

export IFS="${_SP}${_TB}${_NL}"
export LC_ALL=POSIX
export PATH=/bin:/usr/bin:/usr/sbin

unset _TB
unset _NL
unset _SP

set -o errexit # # Exit immediately if a command exits with a non-zero status.
set -o nounset # # Treat unset variables as an error when substituting.

umask 022


# *****************************************************************************
# Get the Cross-tools Configuration
# *****************************************************************************

# Load the host configuration.
#
if [[ ! -f ${K_BLD_ENV_FILE} ]]; then
	echo "E> Cannot find build environment file."
	echo "   => ${K_BLD_ENV_FILE}."
	echo "E> Make sure you are in the cross-tools top-level directory."
	exit 1
fi
source ${K_BLD_ENV_FILE}

# Load the build configuration.
#
if [[ ! -f ${K_BLD_CFG_FILE} ]]; then
	echo "E> Cannot find build configuration file."
	echo "   => ${K_BLD_CFG_FILE}."
	echo "E> Make sure you are in the cross-tools top-level directory."
	exit 1
fi
source ${K_BLD_CFG_FILE}

# The K_BLD_CFG_FILE file sets these four user-specified build components:
#      1) BINUTILS
#      2) GCC
#      3) LIBC
#      4) KERNEL
# These need to be checked and "resolved" to see if the specified values are
# appropriate package versions for this cross-tool builder.  They need to be
# resolved into new variable names with associated packages and md5sum and URL
# information.  The original four variables are unset: BINUTILS, GCC, LIBC and
# KERNEL, as they are not needed after resolving to new variables.

# Resolve: BINUTILS
# Getting: XBT_BINUTILS  XBT_BINUTILS_MD5SUM  XBT_BINUTILS_URL
#
source ${XBT_SCRIPT_DIR}/binutils/binutils-methods.sh
xbt_resolve_binutils_name ${BINUTILS}
unset BINUTILS

# Resolve: GCC
# Getting: XBT_GMP   XBT_GMP_MD5SUM   XBT_GMP_URL
# Getting: XBT_MPC   XBT_MPC_MD5SUM   XBT_MPC_URL
# Getting: XBT_MPFR  XBT_MPFR_MD5SUM  XBT_MPFR_URL
# Getting: XBT_GCC   XBT_GCC_MD5SUM   XBT_GCC_URL
#
source ${XBT_SCRIPT_DIR}/gcc/gcc-methods.sh
xbt_resolve_gcc_name ${GCC}
unset GCC

# Resolve: LIBC
# Getting: XBT_LIB ("glibc" or "uClibc")
# Getting: XBT_LIBC    XBT_LIBC_MD5SUM    XBT_LIBC_URL
# Getting: XBT_LIBC_P  XBT_LIBC_P_MD5SUM  XBT_LIBC_P_URL
#
[[ "${LIBC:0:5}" = "glibc"  ]] && XBT_LIB="glibc"  || true
[[ "${LIBC:0:6}" = "uClibc" ]] && XBT_LIB="uClibc" || true
source ${XBT_SCRIPT_DIR}/${XBT_LIB}/${XBT_LIB}-methods.sh
xbt_resolve_libc_name ${LIBC}
unset LIBC

# Resolve: LINUX
# Getting: XBT_LINUX  XBT_LINUX_MD5SUM  XBT_LINUX_URL
#
source ${XBT_SCRIPT_DIR}/linux/linux-methods.sh
xbt_resolve_linux_name ${LINUX}
unset LINUX

# The K_BLD_CFG_FILE file sets these three user-specified target parameters:
#      1) TARGET ... Target Cross-tool Chain Name
#      2) ARCH ..... Linux Kernel Architecture
#      3) CFLAGS ... Used to Cross-compile Libc
# These TARGET is expanded to a proper tool chain name, and new variables names
# are created; the original three variables are unset: TARGET, ARCH and CFLAGS,
# as they are not needed after resolving to new variables.

XBT_TARGET="${TARGET%-*}-generic-linux-${TARGET#*-}"
XBT_LINUX_ARCH=${ARCH}
XBT_CFLAGS=${CFLAGS}
unset TARGET
unset ARCH
unset CFLAGS

# The K_BLD_CFG_FILE file sets these user-specified cross-tool chain parameters:
#     1) C_PLUS_PLUS
#     2) THREAD_MODEL

XBT_C_PLUS_PLUS="no"
[[ "${C_PLUS_PLUS}" = "yes" ]] && XBT_C_PLUS_PLUS="yes" || true
[[ "${C_PLUS_PLUS}" = "y"   ]] && XBT_C_PLUS_PLUS="yes" || true
unset C_PLUS_PLUS

XBT_THREAD_MODEL="none"
[[ "${THREAD_MODEL}" = "nptl" ]] && XBT_THREAD_MODEL="nptl" || true
unset THREAD_MODEL

# XBT_LIBC_P may be set because GLIBC Ports is available, but it is not needed
# for all architectures.
#
[[ "${XBT_LINUX_ARCH}" = "powerpc" ]] && XBT_LIBC_P="" || true
[[ "${XBT_LINUX_ARCH}" = "i386"    ]] && XBT_LIBC_P="" || true
[[ "${XBT_LINUX_ARCH}" = "x86_64"  ]] && XBT_LIBC_P="" || true

# Report on what we think we are doing.
#
[[ -n "${XBT_GMP}"    ]] && _gmp=${XBT_GMP}           || _gmp="no GMP"
[[ -n "${XBT_MPC}"    ]] && _mpc=${XBT_MPC}           || _mpc="no MPC"
[[ -n "${XBT_MPFR}"   ]] && _mpfr=${XBT_MPFR}         || _mpfr="no MPFR"
[[ -n "${XBT_LIBC_P}" ]] && _libc_p="[${XBT_LIBC_P}]" || _libc_p=""
echo ""
echo "xbuildtool configured for cross-development tool chain:"
echo ""
echo "  Host: ${XBT_HOST}"
echo "Target: ${XBT_TARGET}"
echo " Tools: ${XBT_BINUTILS} ${XBT_GCC} [${_gmp}, ${_mpc}, ${_mpfr}]"
echo "  Libc: ${XBT_LIBC} ${_libc_p}"
echo " Linux: ${XBT_LINUX_ARCH} ${XBT_LINUX}"
echo ""
echo "build gcc with c++: ${XBT_C_PLUS_PLUS}"
echo "  use thread model: ${XBT_THREAD_MODEL}"
echo ""
unset _gmp
unset _mpc
unset _mpfr
unset _libc_p


# *****************************************************************************
# Check for the "clean" Option
# *****************************************************************************

# The K_BLD_CFG_FILE file sets this cross-tool chain parameter: CROSS_TOOL_DIR
#
# CROSS_TOOL_DIR is a directory path; it is relative to the current directory,
# the top-level cross-tools directory.  The resulting directory path is where
# the new directory for the cross-development tool chain is or was created.

if [[ x"${A_ARG1}" = x"clean" ]]; then
	read -p "Remove ${XBT_TARGET} cross-tool chain. (y|n) [n]>"
	if [[ x"${REPLY:0:1}" = x"y" ]]; then
		echo -n "Removing ... "
		rm -rf "${XBT_DIR}/${CROSS_TOOL_DIR}/${XBT_TARGET}"
		echo "done"
	else
		echo "Nothing removed."
	fi
	echo ""
	exit 0
fi


# *****************************************************************************
# Get and Check the Packages
# *****************************************************************************

echo "i> Getting source code packages [be patient, this will not lock up]."
echo "i> Local cache directory: ${K_CACHEDIR}"

xbt_get_file "${XBT_BINUTILS}" ${XBT_BINUTILS_URL}
xbt_get_file "${XBT_GMP}"      ${XBT_GMP_URL}
xbt_get_file "${XBT_MPC}"      ${XBT_MPC_URL}
xbt_get_file "${XBT_MPFR}"     ${XBT_MPFR_URL}
xbt_get_file "${XBT_GCC}"      ${XBT_GCC_URL}
xbt_get_file "${XBT_LIBC}"     ${XBT_LIBC_URL}
xbt_get_file "${XBT_LIBC_P}"   ${XBT_LIBC_P_URL}
xbt_get_file "${XBT_LINUX}"    ${XBT_LINUX_URL}

if [[ ${G_NMISSING} != 0 ]]; then
	echo "Oops -- missing ${G_NMISSING} packages."
	echo ""
	echo -e "${TEXT_BRED}Error${TEXT_NORM}:"
	echo "At least one source package failed to download.  If all source   "
	echo "packages failed to download then check your Internet access.     "
	echo "Listed below are the missing source package name(s) and the last "
	echo "URL used to find the package.  Likely failure possibilities are: "
	echo "=> The URL is wrong, maybe it has changed.                       "
	echo "=> The source package name is no longer at the URL, maybe the    "
	echo "   version name has changed at the URL.                          "
	echo ""
	echo "You can use your web browser to look for the package, and maybe  "
	echo "use Google to look for an alternate site hosting the source,     "
	echo "package, or you can download a ttylinux source distribution ISO  "
	echo "that has the relevant source packages from http://ttylinux.net/  "
	echo "-- remember, the architecture or CPU in the ttylinux source ISO  "
	echo "   name does not matter, as the source packages are just source  "
	echo "   code for any supported architecture."
	echo ""
	while [[ ${G_NMISSING} > 0 ]]; do
		G_NMISSING=$((${G_NMISSING} - 1))
		echo ${G_MISSED_PKG[${G_NMISSING}]}
		echo ${G_MISSED_URL[${G_NMISSING}]}
		unset G_MISSED_PKG[${G_NMISSING}]
		unset G_MISSED_URL[${G_NMISSING}]
		if [[ ${G_NMISSING} != 0 ]]; then
			echo -e "${TEXT_BBLUE}-----${TEXT_NORM}"
		fi
	done
	unset G_NMISSING
	echo ""
fi

K_ERR=0 # Expect xbt_chk_file() to set K_ERR=1 on error.

xbt_chk_file "${XBT_BINUTILS}" ${XBT_BINUTILS_MD5SUM}
xbt_chk_file "${XBT_GMP}"      ${XBT_GMP_MD5SUM}
xbt_chk_file "${XBT_MPC}"      ${XBT_MPC_MD5SUM}
xbt_chk_file "${XBT_GCC}"      ${XBT_GCC_MD5SUM}
xbt_chk_file "${XBT_LIBC}"     ${XBT_LIBC_MD5SUM}
xbt_chk_file "${XBT_LIBC_P}"   ${XBT_LIBC_P_MD5SUM}
xbt_chk_file "${XBT_LINUX}"    ${XBT_LINUX_MD5SUM}

if [[ ${K_ERR} -eq 1 ]]; then
	_dir=$(basename ${XBT_SOURCE_DIR})
	echo "E> File md5sum error."
	echo "E> Remove the bad file(s) from the ${_dir} directory."
	unset _dir
	exit 1
fi

if [[ x"${A_ARG1}" = x"download" ]]; then
	echo ""
	exit 0
fi


# *****************************************************************************
# Miscellaneous Setup for Building a Cross-development Tool Chain
# *****************************************************************************

# Cross-toolset Directory
# This directory will be created under the cross-tools top-level directory.
#
XBT_TOOL_DIR="${XBT_TARGET}"	# Make this directory be the name of the target
				# type e.g., "i486-generic-linux-gnu".

# Avoid inheriting build tool baggage.  Allow no inadvertent host-oriented
# commands or flags.
#
export ARFLAGS=""
export ASFLAGS=""
export CFLAGS=""
export CPPFLAGS=""
export CXXFLAGS=""
export LDFLAGS=""
export MAKEFLAGS=""
#
export AR=""
export AS=""
export CC=""
export CPP=""
export CXX=""
export LD=""
export MAKE="make ${MAKEFLAGS}"
export RANLIB=""
export SIZE=""
export STRIP=""

# Set ${ncpus} to 1 if it is undefined. Check for non-digits in ${ncpus}; if
# any are found then use the number 1.
#
ncpus=${ncpus:-1}
[[ -z "${ncpus//[0-9]}" ]] && ncpus=1

# Setup the bin-link in PATH
#
export PATH=${XBT_BINLINK_DIR}:/bin:/usr/bin:/sbin:/usr/sbin


# *****************************************************************************
# Setup New Cross-development Tool Chain Directory
# *****************************************************************************

# The K_BLD_CFG_FILE file sets this cross-tool chain parameter: CROSS_TOOL_DIR
#
# CROSS_TOOL_DIR is a directory path; it is relative to the current directory,
# the top-level cross-tools directory.  The resulting directory path is where
# the new directory for the cross-development tool chain is created; the new
# cross-development tool chain directory is set in the XBT_TARGET_DIR variable.

XBT_TARGET_DIR="${XBT_DIR}/${CROSS_TOOL_DIR}/${XBT_TOOL_DIR}"

# Scrub any <dir>/.. from the XBT_TARGET_DIR path:
_pathParts=(${XBT_TARGET_DIR//\// })
_newTargetPath=""
for ((_i=1 ; _i < ${#_pathParts[@]} ; _i++)); do
	_l=$_i
	if [[ "${_pathParts[$_i]}" == ".." ]]; then
		_i=$(($_i + 1))
	else
		_j=$(($_i - 1))
		_newTargetPath=${_newTargetPath}/${_pathParts[$_j]}
	fi
done
XBT_TARGET_DIR="${_newTargetPath}/${_pathParts[$_l]}"
unset _pathParts
unset _newTargetPath
unset _i
unset _j
unset _l

XBT_XHOST_DIR="${XBT_TARGET_DIR}/host"
XBT_XTARG_DIR="${XBT_TARGET_DIR}/target"
XBT_XSRC_DIR="${XBT_TARGET_DIR}/_pkg-src"
XBT_TOOLCHAIN_MANIFEST="${XBT_TARGET_DIR}/manifest.txt"
XBT_TARGET_MANIFEST="${XBT_TARGET_DIR}/_pkg-src/manifest.txt"
unset CROSS_TOOL_DIR

if [[ x"${A_ARG1}" = x"clean" ]]; then
	echo ""
	echo "Removing ${XBT_TOOL_DIR} cross-tool chain."
	rm -rf "${XBT_TARGET_DIR}"
	echo ""
	exit 0
fi

if [[ -d "${XBT_TARGET_DIR}" ]]; then
        echo ""
        echo "E> The ${XBT_TOOL_DIR} cross-tool directory already exists."
        echo "=> \${XBT_DIR}/\${CROSS_TOOL_DIR}/${XBT_TOOL_DIR}"
        echo "E> Cowardly quiting."
        exit 1
fi

# That was the last chance to stop before actually making anything.

# All OK, so begin assaulting the file system with a new cross-development tool
# chain directory and begin building it.

mkdir -p "${XBT_TARGET_DIR}"
mkdir -p "${XBT_XHOST_DIR}"
mkdir -p "${XBT_XTARG_DIR}"
mkdir -p "${XBT_XSRC_DIR}"
>"${XBT_TOOLCHAIN_MANIFEST}"
>"${XBT_TARGET_MANIFEST}"

echo ""
exec 4>&1    # Save stdout at fd 4.
CONSOLE_FD=4 #

t1=${SECONDS}

# Use a subshell so the current working directory can be changed and shell
# variables can be assaulted without affecting this script.
(
cd ${XBT_BUILD_DIR}
xbt_build_kernel_headers >${XBT_TARGET_DIR}/_log.0.kernel_headers 2>&1
xbt_build_binutils       >${XBT_TARGET_DIR}/_log.1.binutils       2>&1
xbt_build_gcc_libs       >${XBT_TARGET_DIR}/_log.2.gcc_libs       2>&1
xbt_build_gcc_stage1     >${XBT_TARGET_DIR}/_log.3.gcc_stage1     2>&1
xbt_build_libc_stage1    >${XBT_TARGET_DIR}/_log.4.libc_stage1    2>&1
xbt_build_gcc_stage2     >${XBT_TARGET_DIR}/_log.5.gcc_stage2     2>&1
xbt_build_libc_stage2    >${XBT_TARGET_DIR}/_log.6.libc_stage2    2>&1
xbt_build_gcc_stage3     >${XBT_TARGET_DIR}/_log.7.gcc_stage3     2>&1
xbt_build_libc_stage3    >${XBT_TARGET_DIR}/_log.8.libc_stage3    2>&1
xbt_target_adjust        >${XBT_TARGET_DIR}/_log.9.target_adjust  2>&1
)

if [[ $? -ne 0 ]]; then
	echo -e "${TEXT_BRED}ERROR${TEXT_NORM}"
	echo "Check the build log files.  Probably check:"
	if [[ -f "${XBT_TARGET_DIR}/_log.9.target_adjust" ]]; then
		echo "=> ${XBT_TARGET_DIR}/_log.9.target_adjust"
	elif [[ -f "${XBT_TARGET_DIR}/_log.8.libc_stage3" ]]; then
		echo "=> ${XBT_TARGET_DIR}/_log.8.libc_stage3"
	elif [[ -f "${XBT_TARGET_DIR}/_log.7.gcc_stage3" ]]; then
		echo "=> ${XBT_TARGET_DIR}/_log.7.gcc_stage3"
	elif [[ -f "${XBT_TARGET_DIR}/_log.6.libc_stage2" ]]; then
		echo "=> ${XBT_TARGET_DIR}/_log.6.libc_stage2"
	elif [[ -f "${XBT_TARGET_DIR}/_log.5.gcc_stage2" ]]; then
		echo "=> ${XBT_TARGET_DIR}/_log.5.gcc_stage2"
	elif [[ -f "${XBT_TARGET_DIR}/_log.4.libc_stage1" ]]; then
		echo "=> ${XBT_TARGET_DIR}/_log.4.libc_stage1"
	elif [[ -f "${XBT_TARGET_DIR}/_log.3.gcc_stage1" ]]; then
		echo "=> ${XBT_TARGET_DIR}/_log.3.gcc_stage1"
	elif [[ -f "${XBT_TARGET_DIR}/_log.2.gcc_libs" ]]; then
		echo "=> ${XBT_TARGET_DIR}/_log.2.gcc_libs"
	elif [[ -f "${XBT_TARGET_DIR}/_log.1.binutils" ]]; then
		echo "=> ${XBT_TARGET_DIR}/_log.1.binutils"
	elif [[ -f "${XBT_TARGET_DIR}/_log.0.kernel_headers" ]]; then
		echo "=> ${XBT_TARGET_DIR}/_log.0.kernel_headers"
	fi
	exit 1
fi

t2=${SECONDS}

exec >&4     # Set fd 1 back to stdout.
CONSOLE_FD=1 #

rm -f "${XBT_TARGET_DIR}/_versions"
echo "#!/bin/sh"                             >>${XBT_TARGET_DIR}/_versions
echo "XBT_LINUX_ARCH=\"${XBT_LINUX_ARCH}\""  >>${XBT_TARGET_DIR}/_versions
echo "XBT_LINUX_VER=\"${XBT_LINUX}\""        >>${XBT_TARGET_DIR}/_versions
echo "XBT_LIBC_VER=\"${XBT_LIBC}\""          >>${XBT_TARGET_DIR}/_versions
echo "XBT_XBINUTILS_VER=\"${XBT_BINUTILS}\"" >>${XBT_TARGET_DIR}/_versions
echo "XBT_XGCC_VER=\"${XBT_GCC}\""           >>${XBT_TARGET_DIR}/_versions
chmod 755 "${XBT_TARGET_DIR}/_versions"

rm -f "${XBT_TARGET_DIR}/_xbt_env_set"
xbt_usr_env_set >>${XBT_TARGET_DIR}/_xbt_env_set
chmod 755 "${XBT_TARGET_DIR}/_xbt_env_set"

rm -f "${XBT_TARGET_DIR}/_xbt_env_clr"
xbt_usr_env_clr >>${XBT_TARGET_DIR}/_xbt_env_clr
chmod 755 "${XBT_TARGET_DIR}/_xbt_env_clr"

echo -e "${XBT_TARGET} cross-tool is ${TEXT_GREEN}complete${TEXT_NORM}."
echo "=> $(((${t2}-${t1})/60)) minutes $(((${t2}-${t1})%60)) seconds"


# *****************************************************************************
# Exit OK
# *****************************************************************************

exit 0


# end of file
