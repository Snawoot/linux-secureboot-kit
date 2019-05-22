#!/bin/sh
PATH="/bin:/usr/bin:/sbin:/usr/sbin"
KERNEL_VERSION="${1}"
# shellcheck disable=SC2034
KERNEL_IMAGE="${2}"
GPG_SIGN_HOMEDIR="/var/lib/secureboot/gpg-home"
GPG_SIGN_KEYID="bootsigner@localhost"

GPG=$(command -v gpg2 2>/dev/null) || \
GPG=$(command -v gpg 2>/dev/null)

sign() {
   echo "About to sign file '${1}' with GPG key '${GPG_SIGN_KEYID}'"
   # Don't warn about permissions, we're root and the homedir belongs to a
   # different user, so that's okay.
   "$GPG" --quiet --no-permission-warning --homedir "${GPG_SIGN_HOMEDIR}" --detach-sign --default-key "${GPG_SIGN_KEYID}" < "${1}" > "${1}.sig"
}

sign "/boot/vmlinuz-${KERNEL_VERSION}"
sign "/boot/initramfs-${KERNEL_VERSION}.img"
