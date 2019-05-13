EFIFS=/boot/efi
GRUBCFGLINK:=$(shell ./locate-cfg.sh /etc/grub2-efi.cfg /etc/grub2.cfg /boot/grub2/grub.cfg)
GPG:=$(shell ./locate-bin.sh gpg2 gpg)
OPENSSL=openssl
TAR=tar
GRUB2MKIMAGE:=$(shell ./locate-bin.sh grub2-mkimage grub-mkimage)
GRUB2MKPASSWD:=$(shell ./locate-bin.sh grub2-mkpasswd-pbkdf2 grub-mkpasswd-pbkdf2)
GRUB2MKRELPATH:=$(shell ./locate-bin.sh grub2-mkrelpath grub-mkrelpath)
GRUB2PROBE:=$(shell ./locate-bin.sh grub2-probe grub-probe)
RM=rm
MKDIR=mkdir
CP=cp
CAT=cat
SBSIGN=sbsign
GREP=grep
EFIBOOTMGR=efibootmgr
EFIREADVAR=efi-readvar
EFIUPDATEVAR=efi-updatevar
CERTTOEFISIGLIST=cert-to-efi-sig-list
SIGNEFISIGLIST=sign-efi-sig-list
TOUCH=touch
INSTALL=install
DNF=dnf

all: image efi-keys pgp-key

password: grub.passwd

grub.passwd:
	@echo 'Set password for grub "root" user'
	$(GRUB2MKPASSWD) --iteration-count=65536 | tee $@.tmp
	$(GREP) -Eo 'grub\..+$$' $@.tmp > $@
	$(RM) -f $@.tmp
	@echo "Password hash recorded to '$@'"

grub.cfg: grub.cfg.tmpl.sh grub.passwd
	./$< > $@

boot/grub/grub.cfg: boot_grub_grub.cfg.tmpl.sh
	$(MKDIR) -p boot/grub
	./$< "$(GRUBCFGLINK)" "$(GRUB2PROBE)" "$(GRUB2MKRELPATH)" > $@

pgp-key: pubkey.gpg gpg-key-generated.status

pubkey.gpg: gpg-key-generated.status
	GNUPGHOME=gpg-home $(GPG) --quiet --no-permission-warning --output pubkey.gpg --export bootsigner@localhost --yes

gpg-key-generated.status: gpg-batch
	$(MKDIR) gpg-home && \
	GNUPGHOME=gpg-home $(GPG) --quiet --no-permission-warning --batch --generate-key $<
	$(TOUCH) $@

image: grub-verify.efi

grub-verify.efi: grub-verify-unsigned.efi db.crt db.key
	$(SBSIGN) --key db.key --cert db.crt --output $@ $<

grub-verify-unsigned.efi: grub.cfg memdisk.tar pubkey.gpg
	$(GRUB2MKIMAGE) --format=x86_64-efi --output=$@ --config=grub.cfg --pubkey=pubkey.gpg --memdisk=memdisk.tar all_video boot btrfs cat chain configfile echo efifwsetup efinet ext2 fat font gfxmenu gfxterm gzio halt hfsplus iso9660 jpeg loadenv loopback lvm mdraid09 mdraid1x minicmd normal part_apple part_msdos part_gpt password_pbkdf2 png reboot search search_fs_uuid search_fs_file search_label serial sleep syslinuxcfg test tftp video xfs backtrace usb usbserial_common usbserial_pl2303 usbserial_ftdi usbserial_usbdebug linux tar memdisk verify gcry_rsa gcry_dsa gcry_sha256 hashsum increment blscfg tga

memdisk.tar: boot/grub/grub.cfg
	$(TAR) cf $@ boot

clean:
	$(RM) -rf grub-verify-unsigned.efi grub-verify.efi memdisk.tar PK.key PK.crt KEK.key KEK.crt db.key db.crt gpg-home pubkey.gpg grub.passwd grub.passwd.tmp grub.cfg PK.esl PK.auth *.status boot

efi-keys: PK.crt KEK.crt db.crt PK.key KEK.key db.key PK.esl PK.auth

PK.key PK.crt:
	$(OPENSSL) req -new -x509 -newkey rsa:2048 -subj "/CN=My UEFI Platform Key/" -keyout PK.key -out PK.crt -days 3650 -sha256 -nodes

KEK.key KEK.crt:
	$(OPENSSL) req -new -x509 -newkey rsa:2048 -subj "/CN=My UEFI Key Exchange Key/" -keyout KEK.key -out KEK.crt -days 3650 -sha256 -nodes

db.key db.crt:
	$(OPENSSL) req -new -x509 -newkey rsa:2048 -subj "/CN=My Signing Key/" -keyout db.key -out db.crt -days 3650 -sha256 -nodes

PK.esl: PK.crt
	$(CERTTOEFISIGLIST) -g "$$(uuidgen)" $< $@

PK.auth: PK.key PK.crt PK.esl
	$(SIGNEFISIGLIST) -k PK.key -c PK.crt PK PK.esl PK.auth

PK.crt: PK.key
KEK.crt: KEK.key
db.crt: db.key

efi-keys-backup: backup/PK.esl backup/KEK.esl backup/db.esl backup/dbx.esl

install-gpg-keys: install-gpg-keys.status

install-gpg-keys.status: gpg-key-generated.status
	$(MKDIR) -p /var/lib/secureboot
	$(RM) -rf /var/lib/secureboot/gpg-home
	$(CP) -rvp gpg-home /var/lib/secureboot
	$(TOUCH) $@

install-image: install-image.status

install-image.status: grub-verify.efi
	$(MKDIR) -p $(EFIFS)/EFI/grub-verify
	$(CP) -v $< $(EFIFS)/EFI/grub-verify/$<
	$(TOUCH) $@

install-boot-entry: install-boot-entry.status

install-boot-entry.status: install-image.status install-efi-keys.status install-gpg-keys.status
	$(EFIBOOTMGR) -c -d $$($(GRUB2PROBE) -t disk $(EFIFS)) -L SignedBoot -l '\EFI\grub-verify\grub-verify.efi'
	$(TOUCH) $@

install-efi-keys: install-efi-keys.status

install-efi-keys.status: KEK.crt db.crt PK.auth
	$(EFIUPDATEVAR) -c KEK.crt KEK
	$(EFIUPDATEVAR) -c db.crt db
	$(EFIUPDATEVAR) -f PK.auth PK
	$(TOUCH) $@

install: install-efi-keys install-gpg-keys install-image install-boot-entry

fedora30-install: fedora30-sign.status install

fedora30-sign.status: fedora30-grub-signer.status fedora30-kernel-signer.status
	$(DNF) reinstall -y kernel-core
	$(TOUCH) $@

fedora30-grub-signer.status: fedora30/_etc_default_grub.appendix
	echo >> /etc/default/grub
	$(CAT) $< >> /etc/default/grub
	$(TOUCH) $@

fedora30-kernel-signer.status: fedora30/99-sign-kernel.install
	$(INSTALL) -g root -o root -t /etc/kernel/install.d $^
	$(TOUCH) $@

backup/%.esl:
	[ ! -f install-efi-keys.status ] # disable backup target if keys already installed
	[ -d backup ] || $(MKDIR) -p backup
	$(EFIREADVAR) -v $* -o $@

.PHONY: clean image all pgp-key efi-keys efi-keys-backup install-gpg-keys password install-boot-entry install-image install-efi-keys install fedora30-install
