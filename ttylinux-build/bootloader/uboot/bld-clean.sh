#!/bin/bash

# *****************************************************************************
# Remove any left-over previous build things.
# *****************************************************************************

echo "=> Removing U-Boot, if any."
rm -rf MLO u-boot.bin mkimage *.MAKELOG
