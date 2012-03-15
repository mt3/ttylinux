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
#	This is a top-level makefile used in making an xbuildtool
#	cross-development tool chain for ttylinux distributions.
#
# CHANGE LOG
#
#	14mar12	drj	Added ttylinux beagle_bone cross-tool chain.
#	13feb12	drj	Project reorganization.
#	20feb11	drj	Finished miscellaneous changes for the first release.
#	01jan11	drj	Re-wrote ttylinux cross-tools Makefile for xbuildtool.
#	21dec10	drj	Stupid comment changes.
#	20dec10	drj	Added a mipsel cross-tool chain.
#	10oct10	drj	Removed experimental RTAI support.
#	12apr10	drj	Removed the TIMECMD.
#	03mar10	drj	Removed the arm and i486 targets.
#	20aug09	drj	Added the x86_64 cross-tool chain.
#	22jul09	drj	Added the arm-eabi and arnv5l cross-tool chain.
#	23dec08	drj	Added the i686 cross-tool chain.
#	22nov08	drj	Changed the names of some cleaning targets.
#	13nov08	drj	Replace time with macro TIMECMD.
#	09nov08	drj	Fixed "make clean" not to remove downloaded source.
#	08nov08	drj	Added host-base tool chain proxy.
#	07nov08	drj	Converted to ttylinux usage.
#	13sep07	drj	Original file creation.
#
# *****************************************************************************


# *************************************************************************** #
# Macro Definitions                                                           #
# *************************************************************************** #

# -- Sanity
#
SHELL=/bin/bash


# *****************************************************************************
# Make Targets
# *****************************************************************************

.PHONY:	help setup clean dload
.PHONY:	armv7-2.14-gnueabi mipsel-uclibc powerpc-2.13-gnu
.PHONY:	i486-2.9-gnu i686-2.13-gnu x86_64-2.13-gnu

help:
	@echo ""
	@echo "Make a ttylinux cross-development tool chain."
	@echo ""
	@echo "make setup ... Do this before using any of the other make"
	@echo "               commands.  This needs to be done first, and"
	@echo "               only one time is needed (more will not hurt)."
	@echo ""
	@echo "Make Commands                    ttylinux Cross-tool Chain"
	@echo "-----------------------          -------------------------"
	@echo "make armv7-2.14-gnueabi ........ beagle_bone (linux-3.3.0)"
	@echo "make mipsel-uclibc ............. wrtu54g_tm  (linux-2.6.36.4)"
	@echo "make powerpc-2.13-gnu .......... mac_g4      (linux-2.6.38.1)"
	@echo "make i486-2.9-gnu .............. pc_i486     (linux-2.6.34.6)"
	@echo "make i686-2.13-gnu ............. pc_i686     (linux-2.6.38.1)"
	@echo "make x86_64-2.13-gnu ........... pc_x86_64   (linux-2.6.38.1)"
	@echo ""

setup:
	@./configure

clean:	xbt-build-config.sh
	@scripts/_build-toolchain.sh "clean"

dload:	xbt-build-config.sh
	@scripts/_build-toolchain.sh "download"

armv7-2.14-gnueabi:
	rm -f xbt-build-config.sh
	cp config/ttyl-beagle_bone.cfg xbt-build-config.sh
	./scripts/_build-toolchain.sh

mipsel-uclibc:
	rm -f xbt-build-config.sh
	cp config/ttyl-wrtu54g_tm.cfg xbt-build-config.sh
	./scripts/_build-toolchain.sh

powerpc-2.13-gnu:
	rm -f xbt-build-config.sh
	cp config/ttyl-mac_g4.cfg xbt-build-config.sh
	./scripts/_build-toolchain.sh

i486-2.9-gnu:
	rm -f xbt-build-config.sh
	cp config/ttyl-pc_i486.cfg xbt-build-config.sh
	./scripts/_build-toolchain.sh

i686-2.13-gnu:
	rm -f xbt-build-config.sh
	cp config/ttyl-pc_i686.cfg xbt-build-config.sh
	./scripts/_build-toolchain.sh

x86_64-2.13-gnu:
	rm -f xbt-build-config.sh
	cp config/ttyl-pc_x86_64.cfg xbt-build-config.sh
	./scripts/_build-toolchain.sh


# end of Makefile
