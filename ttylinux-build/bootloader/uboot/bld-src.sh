#!/bin/bash


# *****************************************************************************
# Constants
# *****************************************************************************

K_URL="ftp://ftp.denx.de/pub/u-boot/"


# *****************************************************************************
# Check Command Line Arguments
# *****************************************************************************

if [[ $# -ne 4 ]]; then
	echo "$(basename $0) called with wrong number of arguments ($#)."
	echo "=> Four arguments are needed."
	exit 1
fi
ubootVersion=$1
ubootPatch=$2
destDir=$3
manifest=$4


# *****************************************************************************
# Get the sources.  Make an entry in the manifest.
# *****************************************************************************

_name="u-boot-${ubootVersion}"

cp "${_name}.tar.bz2" "${destDir}"

echo -n "${_name} " >>${manifest}
for ((i=(40-${#_name}) ; i > 0 ; i--)); do
	echo -n "." >>${manifest}
done
echo " ${K_URL}" >>${manifest}

if [[ x"${ubootPatch}" != x"none" ]]; then
	patchDir="${destDir}/u-boot-${ubootVersion}-patch"
	patchFile="p-${ubootVersion}-${TTYLINUX_PLATFORM}-${ubootPatch}.patch"
	mkdir --mode=755 "${patchDir}"
	cp "patch/${patchFile}" "${patchDir}"
	echo "=> patch: ${patchFile}"
	unset patchFile
	unset patchDir
fi

unset _name


# *****************************************************************************
# Cleanup
# *****************************************************************************

unset ubootVersion
unset ubootPatch
unset destDir

unset K_URL


# *****************************************************************************
# Exit OK
# *****************************************************************************

exit 0
