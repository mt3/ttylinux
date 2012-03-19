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
# FILE DESCRIPTION
#
#	This is the makefile used in making a ttylinux distribution.
#
# CHANGE LOG
#
#	18mar12	drj	Call site script even if error in scripts/* script.
#	19feb12	drj	Rewrite for build process reorganization.
#	10feb12	drj	Fixed the "SHELL" macro to be bash.
#	02feb12	drj	Added distdir, distimg, src-dist media.
#	14aug11	drj	Set the "SHELL" macro.
#	22apr11	drj	Added the "media" target; replaced "burncd" target.
#	03mar11	drj	Changed the "iso" target to "boot".
#	01jan11	drj	Miscellaneous fussing.
#	11dec10	drj	Added the use of TTYLINUX_SITE.
#	11dec10	drj	Added calls to site pre and post build scripts.
#	11dec10	drj	Shortened script names.
#	11dec10	drj	Removed the loader.  Changed how clean works.
#	17nov10	drj	Changed the "make dist" order.
#	13nov10	drj	Changed ttylinux.dist-config.sh to ttylinux-config.sh.
#	13nov10	drj	Added bcfg-stnd and bcfg-suid targets.
#	09oct10	drj	Added the "dload" target and miscellaneous fussing.
#	12may10	drj	Changed "source" shell command to "." for non-bash use.
#	10apr10	drj	Changed "false" to "exit 1".
#	30mar10	drj	Changed the "bootcd" target to be "iso".
#	07mar10	drj	"make stat" reports the build configuration.
#	07mar10	drj	Gave a thurough workover.
#	04mar10	drj	Updated for multiple architectures and cross-tools.
#	06dec09	drj	Corrected misspellings.
#	22aug09	drj	Added the "add-on" target.
#	08aug09	drj	Added the "burncd" target.
#	19jul09	drj	Added the "list" target.
#	25oct08	drj	Added "false" to make correct error paths.
#	13oct08	drj	Removed prefix time commands.
#	07oct08	drj	File creation.
#
# *****************************************************************************


TTYLINUX_NAME    := hawberk
TTYLINUX_VERSION := 10.1


# *************************************************************************** #
# Macro Definitions                                                           #
# *************************************************************************** #

# -- Single-Package Target
#
PACKAGE=""

# -- Sanity
#
SHELL=/bin/bash


# *****************************************************************************
# Make Targets
# *****************************************************************************

.PHONY: help
.PHONY: is_build_coherent
.PHONY: getcfg pkglist dload kcfg umount mount list find
.PHONY: stat clean kclean pclean format media
.PHONY: dist init pkgs pkgs_ kernel fsys distdir distimg src-dist

# -----------------------------------------------------------------------------
# -- Default Target
# -----------------------------------------------------------------------------

help:
	@echo ""
	@echo "getcfg   - get default config file from the config directory"
	@echo "pkglist  - make list of source packages using default config"
	@echo "dload    - download source packages"
	@echo "mount    - mount the ttylinux file system image, if found"
	@echo "umount   - unmount the ttylinux file system image, if mounted"
	@echo "list     - list the packages names and versions"
	@echo "find     - list lost or multiply-defined files in the build"
	@echo "stat     - report the status of the ttylinux build process"
	@echo "clean    - remove the entire ttylinux build"
	@echo "kclean   - remove the ttylinux kernel build"
	@echo "pclean   - remove the ttylinux packages build"
	@echo "init     - initialize for building ttylinux"
	@echo "pkgs     - build the ttylinux packages"
	@echo "pkgs_    - continue more building of the ttylinux packages"
	@echo "kernel   - build the ttylinux target kernel"
	@echo "fsys     - create the root file system intrd image"
	@echo "distdir  - collect all the ttylinux target distribution files"
	@echo "distimg  - create target distribution ISO image or tarball"
	@echo "src-dist - get the ttylinux source packages into an ISO image"
	@echo "format   - format target boot SDCard"
	@echo "media    - put the boot system onto media, CDROM or SDCard"
	@echo ""

# -----------------------------------------------------------------------------
# -- Build Status Support
# -----------------------------------------------------------------------------

is_build_coherent:
	@t=`cat var/run/init`;						\
	. ./ttylinux-config.sh;						\
	echo "Building for $${TTYLINUX_PLATFORM}";			\
	if [ "$${t}" != "$${TTYLINUX_PLATFORM}" ]; then			\
		echo "=> Build already in progress for \"$${t}\".";	\
		echo "=> Build MISMATCH.";				\
		echo "=> Did you change ttylinux-config.sh?";		\
		echo "=> Maybe \"make clean\" first.";			\
		exit 1;							\
	fi

var/run/init:
	@if [ ! -f var/run/init ]; then					\
		echo "Not initialized for building.";			\
		exit 1;							\
	fi

var/run/packages:
	@if [ ! -f var/run/packages ]; then				\
		echo "No packages are built.";				\
		exit 1;							\
	fi

var/run/fsys:
	@if [ ! -f var/run/fsys ]; then				\
		echo "The fsys file system is not built.";		\
		exit 1;							\
	fi

var/run/kernel:
	@if [ ! -f var/run/kernel ]; then				\
		echo "The kernel is not built.";			\
		exit 1;							\
	fi

var/run/distdir:
	@if [ ! -f var/run/distdir ]; then				\
		echo "The distribution directory is not built.";	\
		exit 1;							\
	fi

var/run/distimg:
	@if [ ! -f var/run/distimg ]; then				\
		echo "The distribution image is not built.";		\
		exit 1;							\
	fi

# -----------------------------------------------------------------------------
# -- Housekeeping Targets
# -----------------------------------------------------------------------------

getcfg:
	@(								\
	llist=`cd config; ls platform-*/*_defconfig | sed -e 's#.*/##'`;\
	list=($${llist});						\
	declare -i cfg=0;						\
	declare -i cnt="$${#list[@]}";					\
	while [[ $${cfg} == 0 || $${cfg} > $${cnt} ]]; do		\
		echo "";						\
		echo "ttylinux target configurations:";			\
		for (( i=1 ; $${i} <= $${cnt} ; i++ )); do		\
			echo "$${i}) $${list[(($${i}-1))]}";		\
		done;							\
		echo "";						\
		read -p "   Choose from 1 through $${cnt} -> " cfg;	\
	done;								\
	cfg="(($${cfg} - 1))";						\
	echo "";							\
	echo "=> using $${list[$${cfg}]}";				\
	rm --force ttylinux-config.sh;					\
	rm --force ttylinux-pkglst.txt;					\
	cp config/platform-*/$${list[$${cfg}]} ttylinux-config.sh;	\
	)
	@chmod 666 ttylinux-config.sh
	@sed -i ttylinux-config.sh					\
		-e s/TTYLINUX_NAME=.*/TTYLINUX_NAME=${TTYLINUX_NAME}/
	@sed -i ttylinux-config.sh					\
		-e s/TTYLINUX_VERSION=.*/TTYLINUX_VERSION=${TTYLINUX_VERSION}/
	@ls --color -Fl ttylinux-config.sh

ttylinux-config.sh:
	@echo "Need a new ttylinux-config.sh file."
	@echo "=> Run \"make getcf\" or make a new ttylinux-config.sh file."
	@false

ttylinux-pkglst.txt pkglist:	ttylinux-config.sh
	@echo "Regenerating ttylinux-pkglst.txt:"
	@(								\
	. ./ttylinux-config.sh;						\
	rm --force ttylinux-pkglst.txt;					\
	touch ttylinux-pkglst.txt;					\
	for dir in $${TTYLINUX_PACKAGE[@]}; do				\
		echo -n "$$dir " >> ttylinux-pkglst.txt;		\
		for ((i=$${#dir} ; $${i}<40 ; i++)); do			\
			echo -n "." >>ttylinux-pkglst.txt;		\
		done;							\
		. pkg-cfg/$${dir}/bld.sh;				\
		if [[ "$${PKG_TAR}" =~ ".tar.gz"  ]]; then		\
			echo -n " tar.gz " >>ttylinux-pkglst.txt;	\
		fi;							\
		if [[ "$${PKG_TAR}" =~ ".tar.bz2" ]]; then		\
			echo -n " tar.bz2" >>ttylinux-pkglst.txt;	\
		fi;							\
		if [[ "$${PKG_TAR}" =~ ".tgz"     ]]; then		\
			echo -n " tgz    " >>ttylinux-pkglst.txt;	\
		fi;							\
		if [[ "$${PKG_TAR}" =~ ".tbz"     ]]; then		\
			echo -n " tbz    " >>ttylinux-pkglst.txt;	\
		fi;							\
		echo -n " $${PKG_URL}" >>ttylinux-pkglst.txt;		\
		echo "" >>ttylinux-pkglst.txt;				\
	done;								\
	)
	@chmod 666 ttylinux-pkglst.txt
	@ls --color -Fl ttylinux-pkglst.txt

dload:	ttylinux-pkglst.txt scripts/utl-dload.sh
	@echo "Download ttylinux source packages."
	@(scripts/utl-dload.sh)
	@if [ $$? -ne 0 ]; then						\
		echo "Download FAILED.";				\
		exit 1;							\
	fi

kcfg:	scripts/cfg-kernel.sh
	@(scripts/cfg-kernel.sh)

mount:	scripts/sys-mount.sh
	@echo "Mount the ttylinux file system image."
	@(scripts/sys-mount.sh)

umount:	scripts/sys-umount.sh
	@echo "Unmount the ttylinux file system image."
	@(scripts/sys-umount.sh)

list:	ttylinux-pkglst.txt scripts/show-listpackages.sh
	@(scripts/show-listpackages.sh)

find:	scripts/show-lostfiles.sh
	@(scripts/show-lostfiles.sh)

# -----------------------------------------------------------------------------
# -- Build Targets
# -----------------------------------------------------------------------------

dist:	dload clean init pkgs kernel fsys distdir distimg src-dist

stat:
	@. ./ttylinux-config.sh;					\
	t1=$${TTYLINUX_PLATFORM};					\
	if [ -f var/run/init ]; then					\
		t=`cat var/run/init`;					\
		if [ "$${t}" != "$${t1}" ]; then			\
			echo "";					\
			echo "Build MISMATCH.";				\
			echo "=> ttylinux-config.sh    : $${t1}";	\
			echo "=> build initialized for : $${t}";	\
			echo "Did you change ttylinux-config.sh?";	\
			echo "Maybe \"make clean\" first.";		\
		fi							\
	else								\
		t="$${t1}";						\
	fi;								\
	echo "Report status of the $${TTYLINUX_PLATFORM} ttylinux build."
	@(echo -n "> Build ";						\
	[ ! -f var/run/init ] && echo -n "NOT ";			\
	echo "Initialized")
	@(echo -n "> Packages ";					\
	[ ! -f var/run/packages ] && echo -n "NOT ";			\
	echo "Built")
	@(echo -n "> Kernel ";						\
	[ ! -f var/run/kernel ] && echo -n "NOT ";			\
	echo "Built")
	@(echo -n "> File System initrd ";				\
	[ ! -f var/run/fsys ] && echo -n "NOT ";			\
	echo "Built")
	@(echo -n "> Distribution Directory ";				\
	[ ! -f var/run/distdir ] && echo -n "NOT ";			\
	echo "Built")
	@(echo -n "> Distribution Image ";				\
	[ ! -f var/run/distimg ] && echo -n "NOT ";			\
	echo "Built")

${PACKAGE}:	ttylinux-pkglst.txt var/run/init is_build_coherent scripts/bld-packages.sh 
	@(scripts/bld-packages.sh ${PACKAGE})

clean:	scripts/bld-clean.sh
	@if [ -f var/run/init ]; then					\
		echo "Remove the `cat var/run/init` built items.";	\
	else								\
		echo "Remove the built items.";				\
	fi
	@. ./ttylinux-config.sh;					\
	if [ x"$${TTYLINUX_SITE_SCRIPTS:-}" = x"y" ]; then		\
		if [ -x site/bld-clean-0.sh ]; then			\
			(site/bld-clean-0.sh all);			\
		fi							\
	fi;								\
	(scripts/bld-clean.sh all);					\
	mystat=$$?;							\
	if [ x"$${TTYLINUX_SITE_SCRIPTS:-}" = x"y" ]; then		\
		if [ -x site/bld-clean-1.sh ]; then			\
			(site/bld-clean-1.sh all);			\
		fi							\
	fi;								\
	if [ $$mystat -ne 0 ]; then					\
		echo "Clean FAILED.";					\
		exit 1;							\
	fi
	@rm -f var/run/init
	@rm -f var/run/packages
	@rm -f var/run/kernel
	@rm -f var/run/fsys
	@rm -f var/run/distdir
	@rm -f var/run/distimg

kclean:	scripts/bld-clean.sh
	@if [ -f var/run/init ]; then					\
		echo "Remove the `cat var/run/init` kernel.";		\
	else								\
		echo "Remove the kernel.";				\
	fi
	@. ./ttylinux-config.sh;					\
	if [ x"$${TTYLINUX_SITE_SCRIPTS:-}" = x"y" ]; then		\
		if [ -x site/bld-clean-0.sh ]; then			\
			(site/bld-clean-0.sh kernel);			\
		fi							\
	fi;								\
	(scripts/bld-clean.sh kernel);					\
	mystat=$$?;							\
	if [ x"$${TTYLINUX_SITE_SCRIPTS:-}" = x"y" ]; then		\
		if [ -x site/bld-clean-1.sh ]; then			\
			(site/bld-clean-1.sh kernel);			\
		fi							\
	fi;								\
	if [ $$mystat -ne 0 ]; then					\
		echo "Clean FAILED.";					\
		exit 1;							\
	fi
	@rm -f var/run/kernel
	@rm -f var/run/fsys
	@rm -f var/run/distdir
	@rm -f var/run/distimg

pclean:	scripts/bld-clean.sh
	@if [ -f var/run/init ]; then					\
		echo "Remove the `cat var/run/init` packages.";		\
	else								\
		echo "Remove the packages.";				\
	fi
	@. ./ttylinux-config.sh;					\
	if [ x"$${TTYLINUX_SITE_SCRIPTS:-}" = x"y" ]; then		\
		if [ -x site/bld-clean-0.sh ]; then			\
			(site/bld-clean-0.sh packages);			\
		fi							\
	fi;								\
	(scripts/bld-clean.sh packages);				\
	mystat=$$?;							\
	if [ x"$${TTYLINUX_SITE_SCRIPTS:-}" = x"y" ]; then		\
		if [ -x site/bld-clean-1.sh ]; then			\
			(site/bld-clean-1.sh packages);			\
		fi							\
	fi;								\
	if [ $$mystat -ne 0 ]; then					\
		echo "Clean FAILED.";					\
		exit 1;							\
	fi
	@rm -f var/run/packages
	@rm -f var/run/fsys
	@rm -f var/run/distdir
	@rm -f var/run/distimg

init:	scripts/bld-init.sh
	@. ./ttylinux-config.sh;					\
	if [ -f var/run/init ]; then					\
		echo "Already building for `cat var/run/init`";		\
		echo "Maybe \"make clean\" first.";			\
		exit 1;							\
	fi;								\
	echo "Initialize the $${TTYLINUX_PLATFORM} ttylinux build.";	\
	if [ x"$${TTYLINUX_SITE_SCRIPTS:-}" = x"y" ]; then		\
		if [ -x site/bld-init-0.sh ]; then			\
			(site/bld-init-0.sh);				\
		fi							\
	fi;								\
	(scripts/bld-init.sh);						\
	mystat=$$?;							\
	if [ x"$${TTYLINUX_SITE_SCRIPTS:-}" = x"y" ]; then		\
		if [ -x site/bld-init-1.sh ]; then			\
			(site/bld-init-1.sh);				\
		fi							\
	fi;								\
	if [ $$mystat -ne 0 ]; then					\
		echo "Initialize FAILED.";				\
		exit 1;							\
	fi;								\
	echo "$${TTYLINUX_PLATFORM}" >var/run/init

pkgs:	ttylinux-pkglst.txt var/run/init is_build_coherent scripts/bld-packages.sh 
	@echo "Make the ttylinux packages."
	@rm -f var/run/packages
	@. ./ttylinux-config.sh;					\
	if [ x"$${TTYLINUX_SITE_SCRIPTS:-}" = x"y" ]; then		\
		if [ -x site/bld-packages-0.sh ]; then			\
			(site/bld-packages-0.sh);			\
		fi							\
	fi;								\
	(scripts/bld-packages.sh);					\
	mystat=$$?;							\
	if [ x"$${TTYLINUX_SITE_SCRIPTS:-}" = x"y" ]; then		\
		if [ -x site/bld-packages-1.sh ]; then			\
			(site/bld-packages-1.sh);			\
		fi							\
	fi;								\
	if [ $$mystat -ne 0 ]; then					\
		echo "Build FAILED.";					\
		exit 1;							\
	fi
	@touch var/run/packages

pkgs_:	ttylinux-pkglst.txt var/run/init is_build_coherent scripts/bld-packages.sh 
	@echo "Make the ttylinux packages."
	@rm -f var/run/packages
	@. ./ttylinux-config.sh;					\
	if [ x"$${TTYLINUX_SITE_SCRIPTS:-}" = x"y" ]; then		\
		if [ -x site/bld-packages-0.sh ]; then			\
			(site/bld-packages-0.sh);			\
		fi							\
	fi;								\
	(scripts/bld-packages.sh continue);				\
	mystat=$$?;							\
	if [ x"$${TTYLINUX_SITE_SCRIPTS:-}" = x"y" ]; then		\
		if [ -x site/bld-packages-1.sh ]; then			\
			(site/bld-packages-1.sh);			\
		fi							\
	fi;								\
	if [ $$mystat -ne 0 ]; then					\
		echo "Build FAILED.";					\
		exit 1;							\
	fi
	@touch var/run/packages

kernel:	scripts/bld-kernel.sh
	@echo "Make the ttylinux kernel."
	@rm -f var/run/kernel
	@. ./ttylinux-config.sh;					\
	if [ x"$${TTYLINUX_SITE_SCRIPTS:-}" = x"y" ]; then		\
		if [ -x site/bld-kernel-0.sh ]; then			\
			(site/bld-kernel-0.sh);				\
		fi							\
	fi;								\
	(scripts/bld-kernel.sh);					\
	mystat=$$?;							\
	if [ x"$${TTYLINUX_SITE_SCRIPTS:-}" = x"y" ]; then		\
		if [ -x site/bld-kernel-1.sh ]; then			\
			(site/bld-kernel-1.sh);				\
		fi							\
	fi;								\
	if [ $$mystat -ne 0 ]; then					\
		echo "Kernel FAILED.";					\
		exit 1;							\
	fi
	@touch var/run/kernel

fsys:	var/run/packages is_build_coherent scripts/bld-fsys.sh
	@echo "Make ttylinux root file system initrd image."
	@rm -f var/run/fsys
	@. ./ttylinux-config.sh;					\
	if [ x"$${TTYLINUX_SITE_SCRIPTS:-}" = x"y" ]; then		\
		if [ -x site/bld-fsys-0.sh ]; then			\
			(site/bld-fsys-0.sh);				\
		fi							\
	fi;								\
	(scripts/bld-fsys.sh);						\
	mystat=$$?;							\
	if [ x"$${TTYLINUX_SITE_SCRIPTS:-}" = x"y" ]; then		\
		if [ -x site/bld-fsys-1.sh ]; then			\
			(site/bld-fsys-1.sh);				\
		fi							\
	fi;								\
	if [ $$mystat -ne 0 ]; then					\
		echo "File system initrd FAILED.";			\
		exit 1;							\
	fi
	@touch var/run/fsys

distdir:	var/run/fsys var/run/kernel scripts/bld-distdir.sh
	@echo "Make ttylinux distribution directory."
	@rm -f var/run/distdir
	@. ./ttylinux-config.sh;					\
	if [ x"$${TTYLINUX_SITE_SCRIPTS:-}" = x"y" ]; then		\
		if [ -x site/bld-distdir-0.sh ]; then			\
			(site/bld-distdir-0.sh);			\
		fi							\
	fi;								\
	(scripts/bld-distdir.sh);					\
	mystat=$$?;							\
	if [ x"$${TTYLINUX_SITE_SCRIPTS:-}" = x"y" ]; then		\
		if [ -x site/bld-distdir-1.sh ]; then			\
			(site/bld-distdir-1.sh);			\
		fi							\
	fi;								\
	if [ $$mystat -ne 0 ]; then					\
		echo "Distribution directory FAILED.";			\
		exit 1;							\
	fi
	@touch var/run/distdir

distimg:	var/run/distdir scripts/bld-distimg.sh
	@echo "Make a ttylinux distribution image file system."
	@rm -f var/run/distimg
	@. ./ttylinux-config.sh;					\
	if [ x"$${TTYLINUX_SITE_SCRIPTS:-}" = x"y" ]; then		\
		if [ -x site/bld-distimg-0.sh ]; then			\
			(site/bld-distimg-0.sh);			\
		fi							\
	fi;								\
	(scripts/bld-distimg.sh);					\
	mystat=$$?;							\
	if [ x"$${TTYLINUX_SITE_SCRIPTS:-}" = x"y" ]; then		\
		if [ -x site/bld-distimg-1.sh ]; then			\
			(site/bld-distimg-1.sh);			\
		fi							\
	fi;								\
	if [ $$mystat -ne 0 ]; then					\
		echo "Distribution image FAILED.";			\
		exit 1;							\
	fi
	@touch var/run/distimg

src-dist:	scripts/bld-src-dist.sh
	@echo "Make source distribution ISO image."
	@(scripts/bld-src-dist.sh)

format:	scripts/media-format.sh
	@echo "Format ttylinux boot media SDCard."
	@(scripts/media-format.sh)

media:	scripts/bld-media.sh
	@echo "Make ttylinux media."
	@(scripts/bld-media.sh)


# end of Makefile
