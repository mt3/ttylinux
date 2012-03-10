#!/bin/bash

# *****************************************************************************
# Remove any left-over previous build things.
# *****************************************************************************

echo "=> Removing isolinux, if any."
rm -rf isolinux.bin syslinux
