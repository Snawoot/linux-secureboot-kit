#!/bin/sh -e

GRUBCFGLINK="$1"
GRUB2PROBE="$2"
GRUB2MKRELPATH="$3"

GRUBCFGPATH="$(realpath "$GRUBCFGLINK")"
GRUBPFXPATH="$(dirname "$GRUBCFGPATH")"

CFGRELPATH="$("$GRUB2MKRELPATH" "$GRUBCFGPATH")"
PFXRELPATH="$("$GRUB2MKRELPATH" "$GRUBPFXPATH")"
CFGDEV="$("$GRUB2PROBE" -t device "$GRUBCFGPATH")"

. /usr/share/grub/grub-mkconfig_lib

prepare_grub_to_access_device "$CFGDEV"

echo "set prefix=\"$PFXRELPATH\""

cat <<EOF
menuentry "Signed Internal Drive" --unrestricted {
    # load a signed stage2 configuration from boot drive
    if verify_detached ${CFGRELPATH} ${CFGRELPATH}.sig; then
       configfile ${CFGRELPATH}
    else
       echo "Could not verify ${CFGRELPATH}"
    fi
}
EOF
