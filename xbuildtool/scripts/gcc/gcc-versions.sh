# vim: syntax=sh

# For each index i, _GCC[i] _GMP[i] _MPFR[i] are a matched set; which means
# as shown in the rows immediately below, these are a matched set:
#      _GCC[0] _GMP[0] _MPFR[0]
#      _GCC[1] _GMP[1] _MPFR[1]
# and so on.

# *****************************************************************************
# GMP
# *****************************************************************************

_GMP[0]="gmp-4.3.2"
_GMP[1]="gmp-4.3.2"
_GMP[2]="gmp-5.0.2"
_GMP[3]="gmp-6.2.1"

_GMP_MD5SUM[0]="dd60683d7057917e34630b4a787932e8"
_GMP_MD5SUM[1]="dd60683d7057917e34630b4a787932e8"
_GMP_MD5SUM[2]="0bbaedc82fb30315b06b1588b9077cd3"
_GMP_MD5SUM[3]="28971fc21cf028042d4897f02fd355ea"


_GMP_URL[0]="http://ftp.gnu.org/gnu/gmp/"
_GMP_URL[1]="http://ftp.gnu.org/gnu/gmp/"
_GMP_URL[2]="http://ftp.gnu.org/gnu/gmp/"
_GMP_URL[3]="https://ftp.gnu.org/gnu/gmp/"

# *****************************************************************************
# MPC
# *****************************************************************************

_MPC[0]=""
_MPC[1]=""
_MPC[2]="mpc-0.9"
_MPC[3]="mpc-1.2.1"

_MPC_MD5SUM[0]=""
_MPC_MD5SUM[1]=""
_MPC_MD5SUM[2]="0d6acab8d214bd7d1fbbc593e83dd00d"
_MPC_MD5SUM[3]="9f16c976c25bb0f76b50be749cd7a3a8"

_MPC_URL[0]=""
_MPC_URL[1]=""
_MPC_URL[2]="http://www.multiprecision.org/mpc/download/"
_MPC_URL[3]="https://ftp.gnu.org/gnu/mpc/"

# *****************************************************************************
# MPFR
# *****************************************************************************

_MPFR[0]="mpfr-2.4.2"
_MPFR[1]="mpfr-2.4.2"
_MPFR[2]="mpfr-3.1.0"
_MPFR[3]="mpfr-4.1.0"

_MPFR_MD5SUM[0]="89e59fe665e2b3ad44a6789f40b059a0"
_MPFR_MD5SUM[1]="89e59fe665e2b3ad44a6789f40b059a0"
_MPFR_MD5SUM[2]="238ae4a15cc3a5049b723daef5d17938"
_MPFR_MD5SUM[3]="bdd3d5efba9c17da8d83a35ec552baef"

_MPFR_URL[0]="http://www.mpfr.org/mpfr-2.4.2/"
_MPFR_URL[1]="http://www.mpfr.org/mpfr-2.4.2/"
_MPFR_URL[2]="http://www.mpfr.org/mpfr-3.1.0/"
_MPFR_URL[3]="https://www.mpfr.org/mpfr-4.1.0/"

# *****************************************************************************
# GCC
# *****************************************************************************

_GCC[0]="gcc-4.4.4"
_GCC[1]="gcc-4.4.6"
_GCC[2]="gcc-4.6.2"
_GCC[3]="gcc-12.2.0"

_GCC_MD5SUM[0]="7ff5ce9e5f0b088ab48720bbd7203530"
_GCC_MD5SUM[1]="ab525d429ee4425050a554bc9247d6c4"
_GCC_MD5SUM[2]="028115c4fbfb6cfd75d6369f4a90d87e"
_GCC_MD5SUM[3]="d7644b494246450468464ffc2c2b19c3"

_GCC_URL[0]="ftp://ftp.gnu.org/gnu/gcc/${_GCC[0]} http://ftp.gnu.org/gnu/gcc/${_GCC[0]} ftp://sourceware.org/pub/gcc/releases/${_GCC[1]}/"
_GCC_URL[1]="ftp://ftp.gnu.org/gnu/gcc/${_GCC[1]} http://ftp.gnu.org/gnu/gcc/${_GCC[1]} ftp://sourceware.org/pub/gcc/releases/${_GCC[1]}/"
_GCC_URL[2]="ftp://ftp.gnu.org/gnu/gcc/${_GCC[1]} http://ftp.gnu.org/gnu/gcc/${_GCC[1]} ftp://sourceware.org/pub/gcc/releases/${_GCC[1]}/"
_GCC_URL[3]="https://ftp.gnu.org/gnu/gcc/${_GCC[3]}"
