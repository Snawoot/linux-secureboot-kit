#!/bin/sh

set -e

GRUB2MKIMAGE="$1"
shift

# Sanity check
"$GRUB2MKIMAGE" -p /boot/grub --format=x86_64-efi \
    --output=log.txt >log.txt || \
{
    echo >&2 "E: grub2 image builder is not usable"
    exit 1
}

for i in "$@" ; do
    "$GRUB2MKIMAGE" -p /boot/grub \
        --format=x86_64-efi \
        --output=log.txt \
        "$i" >log.txt 2>&1 && \
    echo "$i"
done

rm log.txt

exit 0
