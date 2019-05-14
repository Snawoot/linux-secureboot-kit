#!/bin/sh

set -e

GRUBCFGLINK="$1"
GRUB2PROBE="$2"
GRUB2MKRELPATH="$3"

GRUBCFGPATH="$(realpath "$GRUBCFGLINK")"
GRUBPFXPATH="$(dirname "$GRUBCFGPATH")"

CFGRELPATH="$("$GRUB2MKRELPATH" "$GRUBCFGPATH")"
PFXRELPATH="$("$GRUB2MKRELPATH" "$GRUBPFXPATH")"
CFGDEV="$("$GRUB2PROBE" -t device "$GRUBCFGPATH")"
GRUB_ROOT_PASSWD="$(cat grub.passwd)"

cat <<EOF
set pager=1
set timeout=3
set gfxpayload=keep
set gfxmode=auto

set superusers=root
password_pbkdf2 root ${GRUB_ROOT_PASSWD}

set check_signatures=enforce
EOF

. /usr/share/grub/grub-mkconfig_lib

prepare_grub_to_access_device "$CFGDEV"

cat <<EOF
set prefix="${PFXRELPATH}"
menuentry "Signed Internal Drive" --unrestricted {
    # load a signed stage2 configuration from boot drive
    if verify_detached ${CFGRELPATH} ${CFGRELPATH}.sig; then
       configfile ${CFGRELPATH}
    else
       echo Could verify ${CFGRELPATH}
    fi
}
EOF

