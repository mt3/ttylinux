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
#	This script attempts to download the ttylinux source packages.
#
# CHANGE LOG
#
#	18mar12	drj	Track the failed package downloads and report on them.
#	15feb12	drj	Rewrite for build process reorganization.
#	16nov10	drj	Miscellaneous fussing.
#	01apr10	drj	File creation.
#
# *****************************************************************************


# *************************************************************************** #
#                                                                             #
# S U B R O U T I N E S                                                       #
#                                                                             #
# *************************************************************************** #


# *****************************************************************************
# dload_get_file
# *****************************************************************************

# Usage: dload_get_file <filename> <tag> <url> [url ...]

dload_get_file() {

local fileName="$1"
local fileTag="$2"
local loadedDn="no"
local url

# Go to the urls.
shift
shift

pushd "${TTYLINUX_PKGSRC_DIR}" >/dev/null 2>&1

trap "rm -f ${fileName}.${fileTag}" EXIT

echo -n "i> Checking ${fileName} " 
for ((i=(28-${#fileName}) ; i > 0 ; i--)); do echo -n "."; done

rm -f "${fileName}.download.log"

# Maybe the file doesn't get downloaded.
#
if [[ x"${fileTag}" == x"(cross-tools)" ]]; then
	echo " (comes from cross-tools)" 
	popd >/dev/null 2>&1
	return 0
fi
if [[ x"${fileTag}" == x"(local)" ]]; then
	echo " (local)" 
	popd >/dev/null 2>&1
	return 0
fi

# If the file is already in ${TTYLINUX_PKGSRC_DIR} then return.
#
if [[ -f "${fileName}.${fileTag}" ]]; then
	echo " have it" 
	popd >/dev/null 2>&1
	return 0
fi

echo -n " downloading ... "

# See if there is a local copy of the file.
#
if [[ -f "${K_CACHEDIR}/${fileName}.${fileTag}" ]]; then
	cp "${K_CACHEDIR}/${fileName}.${fileTag}" .
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
_wget="${_wget} -T 15 -nc --progress=dot:binary --tries=3"
_file=""

# Try to download the file from the urls.
#
rm -f "${fileName}.download.log"
>"${fileName}.download.log"
for url in "$@"; do
	_file="${url}/${fileName}.${fileTag}"
	if [[ "${loadedDn}" == "no" ]]; then
		(${_wget} --passive-ftp "${_file}" \
		|| ${_wget} "${_file}" \
		|| true) >>"${fileName}.download.log" 2>&1
		if [[ -f "${fileName}.${fileTag}" ]]; then
			loadedDn="yes"
		fi
	fi
done
unset _wget
unset _file

if [[ "${loadedDn}" == "yes" ]]; then
	echo "done"
	rm -f "${fileName}.download.log"
	chmod 600 ${fileName}.${fileTag}
else
	echo "FAILED"
	G_MISSED_PKG[${G_NMISSING}]="${fileName}.${fileTag}"
	G_MISSED_URL[${G_NMISSING}]="${url}"
	G_NMISSING=$((${G_NMISSING} + 1))
fi

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

K_CACHEDIR=~/Download
K_PKGLIST="ttylinux-pkglst.txt"

G_MISSED_PKG[0]=""
G_MISSED_URL[0]=""
G_NMISSING=0

source ./ttylinux-config.sh    # target build configuration
source ./scripts/_functions.sh # build support

dist_config_setup || exit 1


# *****************************************************************************
# Main Program
# *****************************************************************************

echo "i> Getting source code packages [be patient, this will not lock up]."
echo "i> Local cache directory: ${K_CACHEDIR}"

while read name pad tag url; do
	[[ -z "${name}"         ]] && continue || true
	[[ "${name:0:1}" == "#" ]] && continue || true
	dload_get_file ${name} ${tag} ${url}
done <${K_PKGLIST}

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
		if [[ ${G_NMISSING} != 0 ]]; then
			echo -e "${TEXT_BBLUE}-----${TEXT_NORM}"
		fi
	done
	echo ""
	exit 1
fi


# *****************************************************************************
# Exit with Status
# *****************************************************************************

exit 0


# end of file
