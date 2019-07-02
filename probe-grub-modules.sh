#!/bin/sh

set -e

GRUB2MKIMAGE="$1"
shift

OUTPUT="$(mktemp)"

# Sanity check
"$GRUB2MKIMAGE" -p /boot/grub --format=x86_64-efi \
    --output="$OUTPUT" >/dev/null || \
{
    echo >&2 "E: grub2 image builder is not usable"
    rm "$OUTPUT"
    exit 1
}

for i in "$@" ; do
    "$GRUB2MKIMAGE" -p /boot/grub \
        --format=x86_64-efi \
        --output="$OUTPUT" \
        "$i" >/dev/null 2>&1 && \
    echo "$i"
done

rm "$OUTPUT"
exit 0
