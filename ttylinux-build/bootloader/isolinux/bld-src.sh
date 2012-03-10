#!/bin/bash


# *****************************************************************************
# Constants
# *****************************************************************************

K_URL="http://www.kernel.org/pub/linux/utils/boot/syslinux/"


# *****************************************************************************
# Check Command Line Arguments
# *****************************************************************************

if [[ $# -ne 4 ]]; then
	echo "$(basename $0) called with wrong number of arguments ($#)."
	echo "=> Four arguments are needed."
	exit 1
fi
isolinuxVersion=$1
isolinuxPatch=$2
destDir=$3
manifest=$4


# *****************************************************************************
# Get the sources.  Make an entry in the manifest.
# *****************************************************************************

_name="syslinux-${isolinuxVersion}"

cp "${_name}.tar.bz2" "${destDir}"

echo -n "${_name} " >>${manifest}
for ((i=(40-${#_name}) ; i > 0 ; i--)); do
	echo -n "." >>${manifest}
done
echo " ${K_URL}" >>${manifest}

unset _name


# *****************************************************************************
# Cleanup
# *****************************************************************************

unset isolinuxVersion
unset isolinuxPatch
unset destDir

unset K_URL


# *****************************************************************************
# Exit OK
# *****************************************************************************

exit 0
