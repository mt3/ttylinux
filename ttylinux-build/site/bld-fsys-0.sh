#!/bin/bash
echo ""
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "site file system pre build"
source ./ttylinux-config.sh
_cpu="${TTYLINUX_XBT%%-*}"
if [[ "${TTYLINUX_PLATFORM}" == "beagle_bone" ||
      "${TTYLINUX_PLATFORM}" == "mac_g4"      ||
      "${TTYLINUX_PLATFORM}" == "pc_i686"     ||
      "${TTYLINUX_PLATFORM}" == "pc_x86_64" ]]; then
	cp --verbose \
		site/root_extras.tbz \
		pkg-bin/root_extras-nopackage-${_cpu}.tbz
	chmod 644 pkg-bin/root_extras-nopackage-${_cpu}.tbz
fi
unset _cpu
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo ""
