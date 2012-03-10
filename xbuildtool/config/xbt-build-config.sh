# vim: syntax=sh


# What This File Does
# -------------------
#
# This file specifies the cross-tool chain to be built by xbuildtool; the
# versions of the cross-tool chain parts and their configurations are set in
# this file.

# How To Use This File
# --------------------
#
# In this file there are groups of settings for the same variable e.g.,
#
VARIABLE="value1"
VARIABLE="value2"
VARIABLE="value3"
#
# Select the appropriate value by either
#      a) comment all rows except the one you want, or
#      b) make the last row be the one you want.


# *****************************************************************************
# Components
# *****************************************************************************

BINUTILS="binutils-2.19"
BINUTILS="binutils-2.20"
BINUTILS="binutils-2.21"
BINUTILS="binutils-2.22"

GCC="gcc-4.2.4" # GMP=""          MPC=""        MPFR=""
GCC="gcc-4.4.4" # GMP="gmp-4.3.2" MPC=""        MPFR="mpfr-2.4.2"
GCC="gcc-4.6.2" # GMP="gmp-5.0.2" MPC="mpc-0.9" MPFR="mpfr-3.1.0""

LIBC="uClibc-0.9.31" # LIBC_P=""
LIBC="uClibc-0.9.32" # LIBC_P=""
LIBC="glibc-2.9"     # LIBC_P="glibc-ports-2.9"
LIBC="glibc-2.12.1"  # LIBC_P="glibc-ports-2.12.1"
LIBC="glibc-2.14"    # LIBC_P="glibc-ports-2.14"

LINUX="linux-2.6.34.6"
LINUX="linux-2.6.36.4"
LINUX="linux-2.6.38.1"
LINUX="linux-3.1"


# *****************************************************************************
# Target System
# *****************************************************************************

# GNU uses a triplet name to specify a host or target.  The GNU triplet is the
# basis of the name a compiler tool chain.  The GNU triplet is one of these
# forms (notice the third form is a quadruplet!):
#      cpu-vendor-os
#      cpu-vendor-system
#      cpu-vendor-kernel-system
#
# xbuildtool uses the "cpu-vendor-kernel-system" form, with "-vendor-kernel-"
# always set to "-generic-linux-".  The TARGET variable below specifies the cpu
# and system part of the cpu-vendor-kernel-system.  For eample, TARGET=i486-gnu
# specifies the tool-chain triplet name of i486-generic-linux-gnu.

# uClibc file and directory names use an uppercase 'C', uClibc, but the triplet
# name used by binutils and other GNU tools is with "uclibc", a lowercase 'c',
# so the usage below is "uclibc" with a lowercase 'c'.

# Each row below has TARGET, ARCH and CFLAGS variable settings.  Each of these
# rows is a matched set.
#
# The CFLAGS value is used to cross-compile GLIBC; it is very intentionally set
# to the most general setting for the architecture, as the generated GLIBC may
# be used in different systems of the same ARCH architecture.  When you use the
# generated cross-tool chain to cross-build software packages, you have access
# to these three TARGET ARCH CFLAGS settings as XBT_TARGET, XBT_LINUX_ARCH and
# XBT_CFLAGS respectively; however, you may want to use a more specific CFLAGS
# value to optomize the software packages for a specific architecture/CPU
# variant.  If the CFLAGS value below were set to a more specific variant of
# the ARCH architecture, then the generated cross-tool chain whould be only for
# that variant; you can do that here if you want.

# target triplet          linux kernel
# components              architecture   glibc compile flags
# ----------------------- -------------- -------------------------------------
TARGET="armv5tej-gnueabi" ARCH="arm"     CFLAGS=""
TARGET="armv7-gnueabi"    ARCH="arm"     CFLAGS=""
TARGET="armv7-gnueabi"    ARCH="arm"     CFLAGS="-march=armv7-a -mcpu=cortex-a8"
TARGET="mipsel-uclibc"    ARCH="mips"    CFLAGS="-march=mips32 -mtune=mips32"
TARGET="mipsel-gnu"       ARCH="mips"    CFLAGS="-march=mips32 -mtune=mips32"
TARGET="powerpc-gnu"      ARCH="powerpc" CFLAGS="-mcpu=powerpc -mtune=powerpc"
TARGET="i486-gnu"         ARCH="i386"    CFLAGS="-march=i486 -mtune=i486"
TARGET="i686-gnu"         ARCH="i386"    CFLAGS="-march=i686 -mtune=generic"
TARGET="x86_64-gnu"       ARCH="x86_64"  CFLAGS="-m64"


# *****************************************************************************
# Cross-tool Chain
# *****************************************************************************

# The cross-tool chain will have its own directory which will be created in the
# directory specified here.  The directory specified here is a path relative to
# the top-level cross-tools-X.X directory.  Since each cross-tool chain has its
# own directory, they may all be in the directory specified here.  For instance
# if you have i486, arm and mips cross-tool chains all with glibc-2.9 and
# linux-2.6.20, then you can use something "../cross-tools-2.9-2.6.20" for the
# CROSS_TOOL_DIR value here.
#
CROSS_TOOL_DIR="../cross-tools-2.14-3.1"

# Select whether the cross-tool chain includes C++; if you include C++ then you
# probably need to use a thread model below.
#
C_PLUS_PLUS="no"
C_PLUS_PLUS="yes"

# Choose the thread model for the cross-tool chain.
#
# NOTE -- uClib does not support NPTL (Native POSIX Thread Library) which GCC,
#         GLIBC and Linux have.  If you have a uClibc target, then use "none"
#         for the thread model.
#
THREAD_MODEL="none"
THREAD_MODEL="nptl"


# end of file
