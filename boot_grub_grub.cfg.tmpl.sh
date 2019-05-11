#!/bin/sh -e

GRUBCFGLINK="/etc/grub2-efi.cfg"

GRUBCFGPATH="$(realpath "$GRUBCFGLINK")"

CFGRELPATH="$(grub2-mkrelpath "$GRUBCFGPATH")"
CFGDEV="$(grub2-probe -t device "$GRUBCFGPATH")"

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
