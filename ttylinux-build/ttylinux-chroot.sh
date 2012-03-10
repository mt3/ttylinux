#!/bin/bash

rootfs="$(pwd)/sysroot/"
rootfs="$(pwd)/mnt/"
rootfs="/mnt/loco"

# Remove mounts if something goes wrong.
#
clean_mounts() {
	set +e # Do not exit immediately on command exit with a non-zero status.
	umount -v "${rootfs}/dev/pts"
	umount -v "${rootfs}/dev/shm"
	umount -v "${rootfs}/dev"
	umount -v "${rootfs}/proc"
	umount -v "${rootfs}/sys"
}
trap clean_mounts EXIT

mount -v -o bind /dev   "${rootfs}/dev"
mount -vt devpts devpts "${rootfs}/dev/pts"
mount -vt tmpfs  shm    "${rootfs}/dev/shm"
mount -vt proc   proc   "${rootfs}/proc"
mount -vt sysfs  sysfs  "${rootfs}/sys"

chroot "${rootfs}" \
	/usr/bin/env -i \
	HOME=/root \
	LC_ALL=POSIX \
	TERM=${TERM} \
	USER=root \
	PATH=/bin:/usr/bin:/sbin:/usr/sbin \
	PROMPT_COMMAND="" \
	PS1="$ " \
	/bin/bash --login +h

umount -v "${rootfs}/dev/pts"
umount -v "${rootfs}/dev/shm"
umount -v "${rootfs}/dev"
umount -v "${rootfs}/proc"
umount -v "${rootfs}/sys"

trap - EXIT
