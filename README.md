# linux-secureboot-kit
Tool for complete hardening of Linux boot chain with UEFI Secure Boot. Inspired by [Hanno Heinrichs and Florent Hochwelker blog post](https://www.crowdstrike.com/blog/enhancing-secure-boot-chain-on-fedora-29/).

## Why?

Even if your harddisk is encrypted with full disk encryption, your bootloader config or initramdrive may be spoofed while you left your computer unattended. And this way your encryption key may be silently extracted when you unlock your system next time.

## What does it do?

This kit establishes following signature verification chain: UEFI Secure Boot -> Custom GRUB2 Image with your embedded verification keys -> Signed kernel, initramrs, grub config.

## How to use it?

Here is step by step guide:

### 1. Satisfy requirements

* x64 UEFI-enabled Linux installation with GRUB2 bootloader
* GRUB2 config without `load_env` and `save_env` directives (they will fail boot since all files will have to be signed). If your system uses `grub2-mkconfig` you may edit config templates in `/etc/grub.d` and comment it out and/or turn of related options in `/etc/default/grub`.
* grub2-efi-x64-modules
* grub2-tools
* sbsigntools
* efitools (https://git.kernel.org/pub/scm/linux/kernel/git/jejb/efitools.git). Later one is absent in Fedora repos, so you have to build it yourself. You'll need:
  * openssl-devel
  * gnu-efi-devel
  * perl-File-Slurp
  * help2man
  * (Only for Fedora) [Build script](https://gist.github.com/Snawoot/9cbad8a381b241c5bac5669d00f20620) which workarounds library paths problem.

### 2. Backup current UEFI keys

```
make backup
```

### 3. Clear your current UEFI keys (putting platform into Setup Mode)

Usually, it can be done via BIOS Setup Menu.

When done, verify it. `efi-readvar` output should look like this:

```
# efi-readvar
Variable PK has no entries
Variable KEK has no entries
Variable db has no entries
Variable dbx has no entries
Variable MokList has no entries
```

### 4. Build keys, certificates, signed grub2 image and password hash for grub2 `root` user 

```
sudo make
```

Root access is required for proper embedded boot config generation

### 5. Install UEFI keys, bootloader and boot GPG signing keys

```
sudo make install
```

### 6. Sign all kernels, ramdrives and boot config

All new installed kernels, ramdrives and grub config has to be signed on update. Automation of this process may differ on various distros, but basicly all you have to do is generate detached signature with `gpg` like this:

```sh
FILE=/boot/vmlinuz-5.0.13-300.fc30.x86_64
gpg2 --quiet --no-permission-warning --homedir /var/lib/secureboot/gpg-home --detach-sign --default-key "bootsigner@localhost" < "$FILE" > "$FILE.sig"
```

For Fedora 30 signing automation available via package hooks and can be installed like this:

```
sudo make fedora30-install
```

This command will install required hooks and trigger `kernel-core` package reinstallation to generate all signatures.

### 7. Lockdown your system

Ensure Secure Boot is enabled in your BIOS settings and administrator password is set.
