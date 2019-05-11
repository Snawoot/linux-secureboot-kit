#!/bin/sh

set -e

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
