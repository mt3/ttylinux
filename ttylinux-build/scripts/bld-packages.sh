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
#	This script builds the ttylinux packages.
#
# CHANGE LOG
#
#	16feb12	drj	Rewrite for build process reorganization.
#	22jan12	drj	Minor fussing.
#	23jan11	drj	Minor fussing.
#	16jan11	drj	Added possible TTYLINUX_CPU-specific file list.
#	14jan11	drj	Changed the exe and lib stripping process.
#	13jan11	drj	Added check and show for left-over stuff in BUILD.
#	10jan11	drj	Changed for merging pkg-bld into pkg-cfg.
#	09jan11	drj	Changed pkg_clean to be called after package collection.
#	03jan11	drj	Fixed file stripping.
#	16nov10	drj	Miscellaneous fussing.
#	09oct10	drj	Minor simplifications.
#	02apr10	drj	Unhandle glibc-* and added _files filter.
#	04mar10	drj	Removed ttylinux.site-config.sh and handle glibc-*.
#	23jul09	drj	Switched to bash, simplified output and fixed $NJOBS.
#	07oct08	drj	File creation.
#
# *****************************************************************************


# *************************************************************************** #
#                                                                             #
# S U B R O U T I N E S                                                       #
#                                                                             #
# *************************************************************************** #


# *****************************************************************************
# Get and untar a source package.
# *****************************************************************************

package_get() {

# Function Arguments:
#      $1 ... Package name, like "glibc-2.19".

local srcPkg="$1"
local tarBall=""
local unZipper=""

if [[ -f "${TTYLINUX_PKGSRC_DIR}/${srcPkg}.tgz" ]]; then
	tarBall="${srcPkg}.tgz"
	unZipper="gunzip --force"
fi

if [[ -f "${TTYLINUX_PKGSRC_DIR}/${srcPkg}.tar.gz" ]]; then
	tarBall="${srcPkg}.tar.gz"
	unZipper="gunzip --force"
fi

if [[ -f "${TTYLINUX_PKGSRC_DIR}/${srcPkg}.tbz" ]]; then
	tarBall="${srcPkg}.tbz"
	unZipper="bunzip2 --force"
fi

if [[ -f "${TTYLINUX_PKGSRC_DIR}/${srcPkg}.tar.bz2" ]]; then
	tarBall="${srcPkg}.tar.bz2"
	unZipper="bunzip2 --force"
fi

if [[ -n "${tarBall}" ]]; then
	cp "${TTYLINUX_PKGSRC_DIR}/${tarBall}" .
	${unZipper} "${tarBall}" >/dev/null
	tar --extract --file="${srcPkg}.tar"
	rm --force "${srcPkg}.tar"
fi

}


# *****************************************************************************
# Make a file to list the ttylinux package contents.
# *****************************************************************************

package_list_make() {

# The file cfg-$1/files is an ASCII file that is the list of files from which
# to make the binary package.  cfg-$1/files can have some scripting that
# interprets build script variables to enable the selection of package files
# based upon the shell variables' values, so cfg-$1/files takes some special
# processing.  It is filtered, honoring any ebedded shell scripting, and the
# actual list of binary package files is created as ${TTYLINUX_VAR_DIR}/files

local cfgPkgFiles="$1"

local lineNum=0
local nLineUse=1
local oLineUse=1
local nesting=0

rm --force "${TTYLINUX_VAR_DIR}/files"
>"${TTYLINUX_VAR_DIR}/files"
while read; do
	lineNum=$((${lineNum}+1))
	grep -q "^#if" <<<${REPLY} && {
		if [[ ${nesting} == 1 ]]; then
			echo "E> Cannot nest scripting in cfg-$1/files" >&2
			echo "=> line ${lineNum}: \"${REPLY}\"" >&2
			continue
		fi
		set ${REPLY}
		if [[ $# != 4 ]]; then
			echo "E> IGNORING malformed script in cfg-$1/files" >&2
			echo "=> line ${lineNum}: \"${REPLY}\"" >&2
			continue
		fi
		oLineUse=${nLineUse}
		eval [[ "\$$2" $3 "$4" ]] && nLineUse=1 || nLineUse=0
		nesting=1
	}
	grep -q "^#endif" <<<${REPLY} && { # Manage the #endif lines.  These
		nLineUse=${oLineUse}       # must start in the first column.
		nesting=0
	}
	grep -q "^ *#" <<<${REPLY} && echo "Skipping ${REPLY}"
	grep -q "^ *#" <<<${REPLY} && continue # Manage the comment lines.
	[[ ${nLineUse} == 1 ]] && echo ${REPLY} >>"${TTYLINUX_VAR_DIR}/files"
done <"${cfgPkgFiles}"

}


# *****************************************************************************
# Build a package from source and make a binary package.
# *****************************************************************************

package_xbuild() {

# Function Arguments:
#      $1 ... Package name, like "glibc-2.19".

# Check for the package build script.
#
if [[ ! -f "${TTYLINUX_PKGCFG_DIR}/$1/bld.sh" ]]; then
	echo "E> Cannot find build script."
	echo "=> ${TTYLINUX_PKGCFG_DIR}/$1/bld.sh"
	return 1
fi

# ${TTYLINUX_PKGCFG_DIR}/$1/bld.sh defines several variables and functions:
#
# Functions
#
#	pkg_patch	This function applies any patches or fixups to the
#			source package before building.
#			NOTE -- Patches are applied before package
#				configuration.
#
#	pkg_configure	This function configures the source package for
#			building.
#			NOTE -- Post-configuration patches might be applied.
#
#	pkg_make	This function builds the source package in place in the
#			${TTYLINUX_BUILD_DIR}/packages/ directory
#
#	pkg_install	This function installs any built items into the build
#			root ${TTYLINUX_SYSROOT_DIR}/ directory tree.
#
#	pkg_clean	This function is responsible for cleaning-up,
#			particularly in error conditions.
#			NOTE -- pkg_clean is not called until package
#				collection in the package_collect() function
#				below.
#
# Variables
#
#	PKG_NOBUILD	Flag to not build this package.
#
#	PKG_STATUS	Set by the above function to indicate an error worthy
#			stopping the build process.
#
source "${TTYLINUX_PKGCFG_DIR}/$1/bld.sh"

# Cheap mechanism to skip a package.
#
if [[ x"${PKG_NOBUILD:-}" == x"y" ]]; then
	unset PKG_NOBUILD
	BUILD_MASK=y
	echo -n "Commanded SKIP " >&${CONSOLE_FD}
	return 0
fi

# Self check; the package build script might be for an older version.
#
if [[ "$1" != "${PKG_NAME}-${PKG_VERSION}" ]]; then
	echo 'Blammo!' >&${CONSOLE_FD}
	return 1
fi

echo -n "g." >&${CONSOLE_FD}

# Get the source package, if any.
#
package_get $1

# Get the ttylinux-specific rootfs, if any.
#
if [[ -f "${TTYLINUX_PKGCFG_DIR}/$1/rootfs.tar.bz2" ]]; then
	cp "${TTYLINUX_PKGCFG_DIR}/$1/rootfs.tar.bz2" .
	bunzip2 --force "rootfs.tar.bz2"
	tar --extract --file="rootfs.tar"
	rm --force "rootfs.tar"
fi

# Prepare to create a list of the installed files.
#
rm --force INSTALL_STAMP
rm --force FILES
>INSTALL_STAMP
>FILES
sleep 1 # For detecting files newer than INSTALL_STAMP

# Patch, configure, build and install.  Note: pkg_clean is not called until
# package collection, in the package_collect() function below, unless pkg_build
# reports an error in PKG_STATUS.
#
PKG_STATUS=""
NJOBS=${ncpus:-1} # Setup ${NJOBS} for parallel makes
bitch=$(sed --expression="s/[[0-9]]//g" <<<"${NJOBS}")
[[ -n "${bitch}" ]] && NJOBS=$((${bitch} + 1)) || NJOBS=1
unset bitch
echo -n "b." >&${CONSOLE_FD}
pkg_patch     $1
pkg_configure $1
pkg_make      $1
pkg_install   $1
unset NJOBS
if [[ -n "${PKG_STATUS}" ]]; then
	pkg_clean # Call function pkg_clean from "bld.sh".
	rm --force INSTALL_STAMP
	rm --force FILES
	echo "E> Package error: ${PKG_STATUS}" >&2
	return 1
fi
if [[ x"${TTYLINUX_SITE_SCRIPTS:-}" == x"y" ]]; then
	if [[ -x "${TTYLINUX_SITE_DIR}/pkg_build.sh" ]]; then
		("${TTYLINUX_SITE_DIR}/pkg_build.sh" $1)
	fi
fi
unset PKG_STATUS

# Only the latest revision of libtool understands sysroot, but even it has
# problems when cross-building: remove the .la files.
#
rm --force ${TTYLINUX_SYSROOT_DIR}/lib/*.la
rm --force ${TTYLINUX_SYSROOT_DIR}/usr/lib/*.la

# Remove the un-tarred source package directory, the un-tarred rootfs directory
# and any other needed un-tarred source package directories.
#
[[ -d "$1"     ]] && rm --force --recursive "$1"     || true
[[ -d "rootfs" ]] && rm --force --recursive "rootfs" || true

# Make a list of the installed files.  Remove sysroot and its path component
# from the file names.
#
echo -n "f." >&${CONSOLE_FD}
find ${TTYLINUX_SYSROOT_DIR} -newer INSTALL_STAMP | sort >> FILES
sed --in-place "FILES" --expression="\#^${TTYLINUX_SYSROOT_DIR}\$#d"
sed --in-place "FILES" --expression="s|^${TTYLINUX_SYSROOT_DIR}/||"
rm --force INSTALL_STAMP # All done with the INSTALL_STAMP file.

# Strip when possible.
#
XBT_STRIP="${TTYLINUX_XTOOL_DIR}/host/usr/bin/${TTYLINUX_XBT}-strip"
_bname=""
if [[ x"${TTYLINUX_STRIP_BINS:-}" == x"y" ]]; then
	echo "***** stripping"
	for f in $(<FILES); do
		[[ -d "${TTYLINUX_SYSROOT_DIR}/${f}" ]] && continue || true
		if [[ "$(dirname ${f})" == "bin" ]]; then
			echo "stripping ${f}"
			"${XBT_STRIP}" "${TTYLINUX_SYSROOT_DIR}/${f}" || true
		fi
		if [[ "$(dirname ${f})" == "sbin" ]]; then
			echo "stripping ${f}"
			"${XBT_STRIP}" "${TTYLINUX_SYSROOT_DIR}/${f}" || true
		fi
		if [[ "$(dirname ${f})" == "usr/bin" ]]; then
			echo "stripping ${f}"
			"${XBT_STRIP}" "${TTYLINUX_SYSROOT_DIR}/${f}" || true
		fi
		if [[ "$(dirname ${f})" == "usr/sbin" ]]; then
			echo "stripping ${f}"
			"${XBT_STRIP}" "${TTYLINUX_SYSROOT_DIR}/${f}" || true
		fi
_bname="$(basename ${f})"
[[ $(expr "${_bname}" : ".*\\(.o\)$" ) == ".o" ]] && continue || true
[[ $(expr "${_bname}" : ".*\\(.a\)$" ) == ".a" ]] && continue || true
		if [[ "$(dirname ${f})" == "lib" ]]; then
			echo "stripping ${f}"
			"${XBT_STRIP}" "${TTYLINUX_SYSROOT_DIR}/${f}" || true
		fi
[[ "${_bname}" == "libgcc_s.so"   ]] && continue || true
[[ "${_bname}" == "libgcc_s.so.1" ]] && continue || true
		if [[ "$(dirname ${f})" == "usr/lib" ]]; then
			echo "stripping ${f}"
			"${XBT_STRIP}" "${TTYLINUX_SYSROOT_DIR}/${f}" || true
		fi
	done
else
	echo "***** not stripping"
fi
unset _bname

return 0

}


# *****************************************************************************
# Find the installed man pages, compress them, and adjust the file name in the
# so called database FILES list.
# *****************************************************************************

manpage_compress() {

local i=0
local f=""
#local lFile=""  # link file
#local mFile=""  # man file
#local manDir="" # man file directory

[[ -n "${BUILD_MASK}" ]] && return 0 || true

echo -n "m" >&${CONSOLE_FD}
for f in $(<FILES); do
	[[ -d "${TTYLINUX_SYSROOT_DIR}/${f}" ]] && continue || true
	if [[ -n "$(grep "^usr/share/man/man" <<<${f})" ]]; then
		i=$(($i + 1))
#
# The goal of this is to gzip any non-gziped man pages.  The problem is that
# some of those have more than one sym link to them; how to fixup all the
# symlinks?
#
#		lFile=""
#		mFile=$(basename ${f})
#		manDir=$(dirname ${f})
#		pushd "${TTYLINUX_SYSROOT_DIR}/${manDir}" >/dev/null 2>&1
#		if [[ -L ${mFile} ]]; then
#			lFile="${mFile}"
#			mFile="$(readlink ${lFile})"
#		fi
#		if [[	x"${mFile%.gz}"  == x"${mFile}" && \
#			x"${mFile%.bz2}" == x"${mFile}" ]]; then
#			echo "zipping \"${mFile}\""
#			gzip "${mFile}"
#			if [[ -n "${lFile}" ]]; then
#				rm --force "${lFile}"
#				ln --force --symbolic "${mFile}.gz" "${lFile}"
#			fi
#			sed --in-place "${TTYLINUX_BUILD_DIR}/packages/FILES" \
#				--expression="s|${mFile}$|${mFile}.gz|"
#		fi
#		popd >/dev/null 2>&1
	fi
done
[[ ${#i} -eq 1 ]] && echo -n "___${i}." >&${CONSOLE_FD}
[[ ${#i} -eq 2 ]] && echo -n  "__${i}." >&${CONSOLE_FD}
[[ ${#i} -eq 3 ]] && echo -n   "_${i}." >&${CONSOLE_FD}
[[ ${#i} -eq 4 ]] && echo -n    "${i}." >&${CONSOLE_FD}

return 0

}


# *****************************************************************************
# Collect the installed files into an as-built packge.
# *****************************************************************************

package_collect() {

local fileList=""

[[ -n "${BUILD_MASK}" ]] && return 0 || true

# Make the binary package: make a tarball of the files that is specified in the
# package configuration; this is found in "${TTYLINUX_PKGCFG_DIR}/$1/files".

# Save the list of files actually installed into build-root/
#
cp --force FILES "${TTYLINUX_SYSROOT_DIR}/usr/share/ttylinux/pkg-$1-FILES"
rm --force FILES # All done with the FILES file.

# Look for a package configuration file list.  There does not need to be one.
#
if [[ -f "${TTYLINUX_PKGCFG_DIR}/$1/files" ]]; then
	fileList="${TTYLINUX_PKGCFG_DIR}/$1/files"
fi
if [[ -f "${TTYLINUX_PKGCFG_DIR}/$1/files-${TTYLINUX_PLATFORM}" ]]; then
	fileList="${TTYLINUX_PKGCFG_DIR}/$1/files-${TTYLINUX_PLATFORM}"
fi

# Remark on the current activity.  Probably do something interesting.
#
if [[ -n "${fileList}" ]]; then
	echo -n "p." >&${CONSOLE_FD}
	#
	# This is tricky.  First make "${TTYLINUX_VAR_DIR}/files" from
	# "${fileList}"; then make a binary package from the list in
	# "${TTYLINUX_VAR_DIR}/files".
	#
	package_list_make "${fileList}"
	uTarBall="${TTYLINUX_PKGBIN_DIR}/$1-${TTYLINUX_CPU}.tar"
	cTarBall="${TTYLINUX_PKGBIN_DIR}/$1-${TTYLINUX_CPU}.tbz"
	tar --create \
		--directory="${TTYLINUX_SYSROOT_DIR}" \
		--file="${uTarBall}" \
		--files-from="${TTYLINUX_VAR_DIR}/files" \
		--no-recursion
	bzip2 --force "${uTarBall}"
	mv --force "${uTarBall}.bz2" "${cTarBall}"
	unset uTarBall
	unset cTarBall
	rm --force "${TTYLINUX_VAR_DIR}/files" # Remove the temporary file.
	#
else
	echo -n "XX" >&${CONSOLE_FD}
fi

echo -n "c" >&${CONSOLE_FD}
pkg_clean # Call function pkg_clean from "bld-$1.sh".

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
build_spec_show    || exit 1

BUILD_MASK="" # This is a mechanism to skip building a package, as commanded by
              # the package build script.

ZIPP="" # This is a mechanism to skip already-built packages.
if [[ $# -gt 0 ]]; then
	# "$1" may be unbound so hide it in this if statement.
	# Set the ZIPP flag, if so specified; otherwise reset the package list.
	[[ "$1" == "continue" ]] && ZIPP="y" || TTYLINUX_PACKAGE=("$1")
fi

if [[ ! -d "${TTYLINUX_BUILD_DIR}/packages" ]]; then
	echo "E> The build directory does NOT exist." >&2
	echo "E>      ${TTYLINUX_BUILD_DIR}/packages" >&2
	exit 1
fi

if [[ -z "${TTYLINUX_PACKAGE}" ]]; then
	echo "E> No packages to build.  How did you do that?" >&2
	exit 1
fi


# *****************************************************************************
# Main Program
# *****************************************************************************

echo ""
echo "##### START cross-building packages"
echo "g - getting the source and configuration packages"
echo "b - building and installing the package into build-root"
echo "f - finding installed files"
echo "m - looking for man pages to compress"
echo "p - creating ttylinux-installable package"
echo "c - cleaning"
echo ""

pushd "${TTYLINUX_BUILD_DIR}/packages" >/dev/null 2>&1

if [[ $(ls -1 | wc -l) -ne 0 ]]; then
	echo "packages build directory is not empty:"
	ls -l
	echo ""
fi

#trap "rm --force --recursive ${TTYLINUX_BUILD_DIR}/packages/"* EXIT

T1P=${SECONDS}

for p in ${TTYLINUX_PACKAGE[@]}; do

	[[ -n "${ZIPP}" && -f "${TTYLINUX_VAR_DIR}/log/${p}.done" ]] && continue

	t1=${SECONDS}

	echo -n "${p} ";
	for ((i=(30-${#p}) ; i > 0 ; i--)); do echo -n "."; done
	echo -n " ";

	exec 4>&1    # Save stdout at fd 4.
	CONSOLE_FD=4 #

	if [[ -d "${TTYLINUX_PKGCFG_DIR}/${p}" ]]; then
		rm --force "${TTYLINUX_VAR_DIR}/log/${p}.log"
		package_xbuild  "${p}" >>"${TTYLINUX_VAR_DIR}/log/${p}.log" 2>&1
		manpage_compress       >>"${TTYLINUX_VAR_DIR}/log/${p}.log" 2>&1
		package_collect "${p}" >>"${TTYLINUX_VAR_DIR}/log/${p}.log" 2>&1
		BUILD_MASK=""
	fi

	exec >&4     # Set fd 1 back to stdout.
	CONSOLE_FD=1 #

	if [[ ! -d "${TTYLINUX_PKGCFG_DIR}/${p}" ]]; then
		echo -e -n "${TEXT_BRED}ERROR${TEXT_NORM}"
		echo -e    " no ${TEXT_RED}pkg-cfg/${p}${TEXT_NORM} directory"
		echo       "Check the build log files.  Probably check:"
		echo       "=> ${TTYLINUX_VAR_DIR}/log/${p}.log"
		exit 1
	fi

	rm --force "${TTYLINUX_VAR_DIR}/log/${p}.done"
	>"${TTYLINUX_VAR_DIR}/log/${p}.done"

	echo -n " ... DONE ["
	t2=${SECONDS}
	mins=$(((${t2}-${t1})/60))
	secs=$(((${t2}-${t1})%60))
	[[ ${#mins} -eq 1 ]] && echo -n " "; echo -n "${mins} minutes "
	[[ ${#secs} -eq 1 ]] && echo -n " "; echo -n "${secs} seconds"
	echo "]"

done

T2P=${SECONDS}
echo "=> $(((${T2P}-${T1P})/60)) minutes $(((${T2P}-${T1P})%60)) seconds"
echo ""

#trap - EXIT

if [[ $(ls -1 | wc -l) -ne 0 ]]; then
	echo "packages build directory is not empty:"
	ls -l
	echo ""
fi

popd >/dev/null 2>&1

echo "##### DONE cross-building packages"


# *****************************************************************************
# Exit OK
# *****************************************************************************

exit 0


# end of file
