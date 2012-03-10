#!/bin/bash


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
#	This script builds the cross-development GLIBC.
#
# CHANGE LOG
#
#	19feb12	drj	Added text manifest of tool chain components.
#	11feb12	drj	Bash assault; nicked from Yann E. MORIN
#	11feb12	drj	Get features.h into ${INCLDIR}/
#	31jan11	drj	Removed intermediate lib/crt[1in].o
#	01jan11	drj	Initial version from ttylinux cross-tools.
#
# *****************************************************************************


# *****************************************************************************
# xbt_resolve_libc_name
# *****************************************************************************

# Usage: xbt_resolve_libc_name <string>
#
# Uses:
#      XBT_SCRIPT_DIR
#
# Sets:
#     XBT_LIBC
#     XBT_LIBC_MD5SUM
#     XBT_LIBC_URL
#     XBT_LIBC_P
#     XBT_LIBC_P_MD5SUM
#     XBT_LIBC_P_URL

xbt_resolve_libc_name() {

source ${XBT_SCRIPT_DIR}/glibc/glibc-versions.sh

XBT_LIBC=""
XBT_LIBC_MD5SUM=""
XBT_LIBC_URL=""

XBT_LIBC_P=""
XBT_LIBC_P_MD5SUM=""
XBT_LIBC_P_URL=""

for (( i=0 ; i<${#_GLIBC[@]} ; i=(($i+1)) )); do
	if [[ "${1}" = "${_GLIBC[$i]}" ]]; then
		XBT_LIBC="${_GLIBC[$i]}"
		XBT_LIBC_MD5SUM="${_GLIBC_MD5SUM[$i]}"
		XBT_LIBC_URL="${_GLIBC_URL[$i]}"
		XBT_LIBC_P="${_GLIBC_P[$i]}"
		XBT_LIBC_P_MD5SUM="${_GLIBC_P_MD5SUM[$i]}"
		XBT_LIBC_P_URL="${_GLIBC_P_URL[$i]}"
		i=${#_GLIBC[@]}
	fi
done

unset _GLIBC
unset _GLIBC_MD5SUM
unset _GLIBC_URL
unset _GLIBC_P
unset _GLIBC_P_MD5SUM
unset _GLIBC_P_URL

if [[ -z "${XBT_LIBC}" ]]; then
	echo "E> Cannot resolve \"${1}\""
	return 1
fi

return 0

}


# *****************************************************************************
# xbt_build_libc_stage1
# *****************************************************************************

# A cross-built target GLIBC cannot be build yet because the cross-compiling
# GCC is not yet complete enough to do the job of cross building a complete
# target GLIBC.  But the cross-compiling GCC is good enough to build and
# install cross-built target GLIBC header files and a few object files, which
# later can be used to build a better cross-compiling GCC.
#
# The option --prefix=/usr is used because the GLIBC configuration and/or build
# process may check if the prefix is /usr and do some unwanted thing if not so.
# Specifically, GLIBC may use a sysroot that does not use the standard Linux
# directory layout wherein sysroot could not then be used as a basis for the
# root file system on a target system in a way that is compatible with a normal
# GLIBC installation.

xbt_build_libc_stage1() {

local msg
local WITH_TLS_TRHEAD

msg="Building ${XBT_LIBC} Stage 1 "
echo -n "${msg}"          >&${CONSOLE_FD}
xbt_print_dots_35 ${#msg} >&${CONSOLE_FD}
echo -n " "               >&${CONSOLE_FD}

xbt_debug_break ""

# Find, uncompress and untarr ${XBT_LIBC}.  Get library ports parts and make
# manifest entries.
#
xbt_src_get ${XBT_LIBC} "${XBT_XSRC_DIR}"
#
echo -n "${XBT_LIBC} " >>"${XBT_TOOLCHAIN_MANIFEST}"
echo -n "${XBT_LIBC} " >>"${XBT_TARGET_MANIFEST}"
for ((i=(40-${#XBT_LIBC}) ; i > 0 ; i--)) do
        echo -n "." >>"${XBT_TOOLCHAIN_MANIFEST}"
        echo -n "." >>"${XBT_TARGET_MANIFEST}"
done
echo " ${XBT_LIBC_URL}" >>"${XBT_TOOLCHAIN_MANIFEST}"
echo " ${XBT_LIBC_URL}" >>"${XBT_TARGET_MANIFEST}"
#
case "${XBT_LINUX_ARCH}" in
	arm)	echo "${XBT_LINUX_ARCH}: Getting ports for ${XBT_LIBC}"
		xbt_src_get ${XBT_LIBC_P} "${XBT_XSRC_DIR}"
		mv -v ${XBT_LIBC_P} ${XBT_LIBC}/ports
		#
		echo -n "${XBT_LIBC_P} " >>"${XBT_TOOLCHAIN_MANIFEST}"
		echo -n "${XBT_LIBC_P} " >>"${XBT_TARGET_MANIFEST}"
		for ((i=(40-${#XBT_LIBC_P}) ; i > 0 ; i--)) do
        		echo -n "." >>"${XBT_TOOLCHAIN_MANIFEST}"
        		echo -n "." >>"${XBT_TARGET_MANIFEST}"
		done
		echo " ${XBT_LIBC_P_URL}" >>"${XBT_TOOLCHAIN_MANIFEST}"
		echo " ${XBT_LIBC_P_URL}" >>"${XBT_TARGET_MANIFEST}"
		#
		;;
	mips)	echo "${XBT_LINUX_ARCH}: Getting ports for ${XBT_LIBC}"
		xbt_src_get ${XBT_LIBC_P} "${XBT_XSRC_DIR}"
		mv -v ${XBT_LIBC_P} ${XBT_LIBC}/ports
		#
		echo -n "${XBT_LIBC_P} " >>"${XBT_TOOLCHAIN_MANIFEST}"
		echo -n "${XBT_LIBC_P} " >>"${XBT_TARGET_MANIFEST}"
		for ((i=(40-${#XBT_LIBC_P}) ; i > 0 ; i--)) do
        		echo -n "." >>"${XBT_TOOLCHAIN_MANIFEST}"
        		echo -n "." >>"${XBT_TARGET_MANIFEST}"
		done
		echo " ${XBT_LIBC_P_URL}" >>"${XBT_TOOLCHAIN_MANIFEST}"
		echo " ${XBT_LIBC_P_URL}" >>"${XBT_TARGET_MANIFEST}"
		#
		;;
esac

# Use any patches; make manifest entries.
#
cd ${XBT_LIBC}
for p in ${XBT_PATCH_DIR}/${XBT_LIBC}-*.patch; do
	if [[ -f "${p}" ]]; then
		patch -Np1 -i "${p}"
		cp "${p}" "${XBT_XSRC_DIR}"
		_p="$(basename ${p})"
		chmod 644 "${XBT_XSRC_DIR}/${_p}"
		echo "=> patch: ${_p}" >>"${XBT_TOOLCHAIN_MANIFEST}"
		echo "=> patch: ${_p}" >>"${XBT_TARGET_MANIFEST}"
		unset _p
	fi
done; unset p
cd ..

# The GLIBC documentation recommends building GLIBC outside of the source
# directory in a dedicated build directory.
#
rm -rf	"build-glibc"
mkdir	"build-glibc"
cd	"build-glibc"

WITH_TLS_TRHEAD=""
if [[ "${XBT_THREAD_MODEL}" = "nptl" ]]; then
	WITH_TLS_TRHEAD="--with-tls --with-__thread"
fi

# Configure GLIBC for building.
#
echo "# XBT_CONFIG **********"
#
# Tell GLIBC where the bash is _on_the_target_.
# Notes:
# - ${ac_cv_path_BASH_SHELL} is only used to set BASH_SHELL
# - ${BASH_SHELL}            is only used to set BASH
# - ${BASH}                  is only used to set the shebang
#                            in two scripts to run on the target
# This should safely bypass the host bash detection at compile time.
# -- This bash assault is nicked from Yann E. MORIN crosstool-ng-1.14.0
#
# The GLIBC configuration fails on some pthread capability checking; pthread
# capability is not yet needed so config.cache is used to bypass the check.
# It is not clear that this failure is because the configuration process
# wrongly uses host tools, or not; but the capability is not needed.
rm -f config.cache
echo "ac_cv_path_BASH_SHELL=/bin/bash" >>config.cache
echo "libc_cv_forced_unwind=yes"       >>config.cache
echo "libc_cv_c_cleanup=yes"           >>config.cache
echo "libc_cv_gnu89_inline=yes"        >>config.cache
#
BUILD_CC="gcc" \
AR="${XBT_XHOST_DIR}/usr/bin/${XBT_TARGET}-ar" \
CC="${XBT_XHOST_DIR}/usr/bin/${XBT_TARGET}-gcc" \
CPP="${XBT_XHOST_DIR}/usr/bin/${XBT_TARGET}-cpp" \
RANLIB="${XBT_XHOST_DIR}/usr/bin/${XBT_TARGET}-ranlib" \
CFLAGS="${XBT_CFLAGS} -O2" \
../${XBT_LIBC}/configure \
	--build=${XBT_BUILD} \
	--host=${XBT_TARGET} \
	--prefix=/usr \
	--cache-file=config.cache \
	--enable-add-ons \
	--enable-kernel=${XBT_LINUX#*-} \
	--disable-multilib \
	--disable-profile \
	--disable-nls \
	--with-binutils=${XBT_XHOST_DIR}/usr/bin \
	--with-headers=${XBT_XTARG_DIR}/usr/include \
	${WITH_TLS_TRHEAD} \
	--without-cvs \
	--without-gd || exit 1

xbt_debug_break "configured ${XBT_LIBC} for stage 1"

# Install GLIBC header files.
#
echo "# XBT_INSTALL **********"
xbt_files_timestamp
#
PATH=${XBT_XHOST_DIR}/usr/bin:${PATH} \
make cross-compiling=yes install_root=${XBT_XTARG_DIR} install-headers || exit 1
#
# Some GLIBC header files are not installed.  The next GCC build will need
# them, so manually install them here.  Stubs.h may be an empty file, but GCC
# seems to build OK with it.
# stubs.h ....... http://gcc.gnu.org/ml/gcc/2002-01/msg00900.html
# stdio_lim.h ... http://sources.redhat.com/ml/libc-alpha/2003-11/msg00045.html
INSTCMD="install --mode=644 --group=$(id -g) --owner=$(id -u)"
INCLDIR="${XBT_XTARG_DIR}/usr/include"
mkdir -p "${INCLDIR}/bits"
mkdir -p "${INCLDIR}/gnu"
${INSTCMD} bits/stdio_lim.h                   ${INCLDIR}/bits
${INSTCMD} ../${XBT_LIBC}/include/gnu/stubs.h ${INCLDIR}/gnu
${INSTCMD} ../${XBT_LIBC}/include/features.h  ${INCLDIR}/
unset INSTCMD
unset INCLDIR
#
# So far, for GLIBC, only header files have been installed.  The next GCC build
# step will need the following three object files; manually build and install
# them.
mkdir -p "${XBT_XTARG_DIR}/lib"
PATH=${XBT_XHOST_DIR}/usr/bin:${PATH} \
make csu/subdir_lib || exit 1
INSTCMD="install --group=$(id -g) --owner=$(id -u)"
${INSTCMD} --mode=644 csu/crt1.o ${XBT_XTARG_DIR}/lib
${INSTCMD} --mode=644 csu/crti.o ${XBT_XTARG_DIR}/lib
${INSTCMD} --mode=644 csu/crtn.o ${XBT_XTARG_DIR}/lib
unset INSTCMD
#
# The next GCC build step will need libc.so, maybe for libgcc_s.so, but libc.so
# cannot yet be built.  The solution is to create an empty libc.so so that the
# next version of the cross-compiling GCC can be built.
#
# Diversion:  The final cross-compiling GCC cannot use the empty libc.so that
#             is being built here; therefore, the next GCC build step will
#             still create an incomplete GCC.
#
# Use /dev/null as a C source file to create an empty libc.so.
[[ "${XBT_LINUX_ARCH}" = "x86_64" ]] && CFLAG="-m64" || CFLAG=""
mkdir -p "${XBT_XTARG_DIR}/lib"
${XBT_XHOST_DIR}/usr/bin/${XBT_TARGET}-gcc ${CFLAG} \
	-nostdlib -nostartfiles -shared -x c /dev/null \
	-o ${XBT_XTARG_DIR}/lib/libc.so || exit 1
#${XBT_XHOST_DIR}/usr/bin/${XBT_TARGET}-gcc ${CFLAG} \
#	-nostdlib -nostartfiles -shared -x c /dev/null \
#	-o ${XBT_XTARG_DIR}/lib/libm.so || exit 1
unset CFLAG

echo "# XBT_FILES **********"
xbt_files_find

xbt_debug_break "installed ${XBT_LIBC} for stage 1"

# Move out and clean up.
#
cd ..
rm -rf "build-glibc"
rm -rf "${XBT_LIBC}"

echo "done" >&${CONSOLE_FD}

return 0

}


# *****************************************************************************
# xbt_build_libc_stage2
# *****************************************************************************

xbt_build_libc_stage2() {

# A fairly complete GCC cross-compiler is available; it does not have a proper
# libgcc_s.so, but that is assumed to not be needed to cross build a final and
# complete target GLIBC.

local msg
local WITH_TLS_TRHEAD

msg="Building ${XBT_LIBC} Stage 2 "
echo -n "${msg}"          >&${CONSOLE_FD}
xbt_print_dots_35 ${#msg} >&${CONSOLE_FD}
echo -n " "               >&${CONSOLE_FD}

xbt_debug_break ""

# Find, uncompress and untarr ${XBT_LIBC}.
#
xbt_src_get ${XBT_LIBC}
case "${XBT_LINUX_ARCH}" in
	arm)	echo "${XBT_LINUX_ARCH}: Getting ports for ${XBT_LIBC}"
		xbt_src_get ${XBT_LIBC_P}
		mv -v ${XBT_LIBC_P} ${XBT_LIBC}/ports
		;;
	mips)	echo "${XBT_LINUX_ARCH}: Getting ports for ${XBT_LIBC}"
		xbt_src_get ${XBT_LIBC_P}
		mv -v ${XBT_LIBC_P} ${XBT_LIBC}/ports
		;;
esac

cd ${XBT_LIBC}
for p in ${XBT_PATCH_DIR}/${XBT_LIBC}-*.patch; do
	if [[ -f "${p}" ]]; then patch -Np1 -i "${p}"; fi
done; unset p
cd ..

# The GLIBC documentation recommends building GLIBC outside of the source
# directory in a dedicated build directory.
#
rm -rf	"build-glibc"
mkdir	"build-glibc"
cd	"build-glibc"

WITH_TLS_TRHEAD=""
if [[ "${XBT_THREAD_MODEL}" = "nptl" ]]; then
	WITH_TLS_TRHEAD="--with-tls --with-__thread"
fi

# Configure GLIBC for building.
#
echo "# XBT_CONFIG **********"
#
# Cross-tools is not multilib and /lib64 is NOT used; GLIBC is configured to
# use /lib.
rm -f configparms
[[ "${XBT_LINUX_ARCH}" = "x86_64" ]] && echo "slibdir=/lib" >>configparms
#
# Tell GLIBC where the bash is _on_the_target_.
# Notes:
# - ${ac_cv_path_BASH_SHELL} is only used to set BASH_SHELL
# - ${BASH_SHELL}            is only used to set BASH
# - ${BASH}                  is only used to set the shebang
#                            in two scripts to run on the target
# This should safely bypass the host bash detection at compile time.
# -- This bash assault is nicked from Yann E. MORIN crosstool-ng-1.14.0
#
# The GLIBC configuration fails on some pthread capability checking.  It is
# assumed that GLIBC support for pthread will not be built if this checking
# fails.  Config.cache is used to bypass the check.  It is assumed that the
# GLIBC capability that is allowed to be built by using this bypass can be
# used by the final cross development environment, and the reason that the
# pthread capability checking fails is because the final and complete GCC, or
# GLIBC, is not yet built.
# It is not clear that this configuration failure is because the configuration
# process wrongly uses host tools, or not.
rm -f config.cache
echo "ac_cv_path_BASH_SHELL=/bin/bash" >>config.cache
echo "libc_cv_forced_unwind=yes"       >>config.cache
echo "libc_cv_c_cleanup=yes"           >>config.cache
echo "libc_cv_gnu89_inline=yes"        >>config.cache
#
BUILD_CC="gcc" \
AR="${XBT_XHOST_DIR}/usr/bin/${XBT_TARGET}-ar" \
CC="${XBT_XHOST_DIR}/usr/bin/${XBT_TARGET}-gcc" \
CPP="${XBT_XHOST_DIR}/usr/bin/${XBT_TARGET}-cpp" \
RANLIB="${XBT_XHOST_DIR}/usr/bin/${XBT_TARGET}-ranlib" \
CFLAGS="${XBT_CFLAGS} -O2" \
../${XBT_LIBC}/configure \
	--build=${XBT_BUILD} \
	--host=${XBT_TARGET} \
	--prefix=/usr \
	--cache-file=config.cache \
	--libdir=/usr/lib \
	--libexecdir=/usr/lib/glibc \
	--enable-add-ons \
	--enable-kernel=${XBT_LINUX#*-} \
	--enable-nls \
	--enable-shared \
	--disable-multilib \
	--disable-profile \
	--with-binutils=${XBT_XHOST_DIR}/usr/bin \
	--with-headers=${XBT_XTARG_DIR}/usr/include \
	${WITH_TLS_TRHEAD} \
	--without-cvs \
	--without-gd || exit 1

xbt_debug_break "configured ${XBT_LIBC} for stage 2"

# If there are multiple host cpus then take advantage of parallel making.
#
njobs=$((${ncpus} + 1))
sed -e "s/^# PARALLELMFLAGS = -j 4/PARALLELMFLAGS = -j ${njobs}/" -i Makefile
unset njobs

# Build GLIBC.
#
echo "# XBT_CONFIG **********"
PATH=${XBT_XHOST_DIR}/usr/bin:${PATH} make || exit 1

xbt_debug_break "maked ${XBT_LIBC} for stage 2"

# Install GLIBC.
#
echo "# XBT_INSTALL **********"
xbt_files_timestamp
#
rm -f ${XBT_XTARG_DIR}/lib/crt1.o  # Remove intermediate crt1.o
rm -f ${XBT_XTARG_DIR}/lib/crti.o  # Remove intermediate crti.o
rm -f ${XBT_XTARG_DIR}/lib/crtn.o  # Remove intermediate crtn.o
rm -f ${XBT_XTARG_DIR}/lib/libc.so # Remove the empty libc.so.
PATH=${XBT_XHOST_DIR}/usr/bin:${PATH} \
make install_root=${XBT_XTARG_DIR} install || exit 1
#PATH=${XBT_XHOST_DIR}/usr/bin:${PATH} \
#make install_root=${XBT_XTARG_DIR} localedata/install-locales || exit 1
#
rm -rf "${XBT_XTARG_DIR}/usr/info" # This is not needed.
#
if [ "${XBT_LINUX_ARCH}" = "x86_64" ]; then
	# Remove "/lib64" from /usr/bin/ldd as cross-tools is NOT multilib and
	# uses "/lib" with NO "/lib64".
	sed -e '/RTLDLIST/s|/ld-linux.so.2 /lib64||' \
		-i ${XBT_XTARG_DIR}/usr/bin/ldd
fi
#
echo "# XBT_FILES **********"
xbt_files_find

xbt_debug_break "installed ${XBT_LIBC} for stage 2"

# Move out and clean up.
#
cd ..
rm -rf "build-glibc"
rm -rf "${XBT_LIBC}"

echo "done [${XBT_LIBC} is complete]" >&${CONSOLE_FD}

return 0

}


# *****************************************************************************
# xbt_build_libc_stage3
# *****************************************************************************

xbt_build_libc_stage3() {

echo "# ********** Not implemented.  Maybe it should be."
return 0

}


# end of file
