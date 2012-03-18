#!/bin/bash
echo ""
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "site kernel post build"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo ""

# Silly bag of stuff here to put a thinkpad's fan back to "auto" control after
# the kernel build process.
#
set_e=${-//[^e]}
set +e
#
(rmmod thinkpad_acpi)                   2>/dev/null
(modprobe thinkpad_acpi fan_control=1)  2>/dev/null
(echo "level auto" >/proc/acpi/ibm/fan) 2>/dev/null
#
[[ x"${set_e}" == x"e" ]] && set -e
unset set_e

