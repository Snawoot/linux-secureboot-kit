#!/bin/sh
KERNEL_VERSION="${1}"
# shellcheck disable=SC2034
KERNEL_IMAGE="${2}"

rm -f "/boot/vmlinuz-${KERNEL_VERSION}.sig" "/boot/initramfs-${KERNEL_VERSION}.img.sig"

exit 0
