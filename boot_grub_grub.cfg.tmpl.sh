#!/bin/sh -e

GRUBCFGLINK="$1"
GRUB2PROBE="$2"
GRUB2MKRELPATH="$3"

GRUBCFGPATH="$(realpath "$GRUBCFGLINK")"

CFGRELPATH="$("$GRUB2MKRELPATH" "$GRUBCFGPATH")"
CFGDEV="$("$GRUB2PROBE" -t device "$GRUBCFGPATH")"

echo $CFGRELPATH
echo $CFGDEV

. /usr/share/grub/grub-mkconfig_lib

prepare_grub_to_access_device "$CFGDEV"

cat <<EOF
menuentry "Signed Internal Drive" --unrestricted {
    # load a signed stage2 configuration from boot drive
    if verify_detached ${CFGRELPATH} ${CFGRELPATH}.sig; then
       configfile ${CFGRELPATH}
    else
       echo Could verify ${CFGRELPATH}
    fi
}
EOF
