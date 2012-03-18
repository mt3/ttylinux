#!/bin/bash
echo ""
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "site kernel pre build"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo ""

# Silly bag of stuff here to get a thinkpad's fan running so that the kernel
# build process doesn't overheat the CPU and cause the system to shut down.
#
set_e=${-//[^e]}
set +e
#
(rmmod thinkpad_acpi)                         2>/dev/null
(modprobe thinkpad_acpi fan_control=1)        2>/dev/null
(echo "level disengaged" >/proc/acpi/ibm/fan) 2>/dev/null
#
[[ x"${set_e}" == x"e" ]] && set -e
unset set_e
