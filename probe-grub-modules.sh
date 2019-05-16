#!/bin/sh

set -e

GRUB2MKIMAGE="$1"
shift

# Sanity check
"$GRUB2MKIMAGE" -p /boot/grub --format=x86_64-efi \
    --output=/dev/null >/dev/null || \
{
    echo >&2 "E: grub2 image builder is not usable"
    exit 1
}

for i in "$@" ; do
    "$GRUB2MKIMAGE" -p /boot/grub \
        --format=x86_64-efi \
        --output=/dev/null \
        "$i" >/dev/null 2>&1 && \
    echo "$i"
done

exit 0