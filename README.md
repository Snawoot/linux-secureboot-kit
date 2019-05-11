# linux-secureboot-kit
Tool for complete hardening of Linux boot chain with UEFI Secure Boot. Inspired by [Hanno Heinrichs and Florent Hochwelker blog post](https://www.crowdstrike.com/blog/enhancing-secure-boot-chain-on-fedora-29/).

## Why?

Even if your harddisk is encrypted with full disk encryption, your bootloader config or initramdrive may be spoofed while you left your computer unattended. And this way your encryption key may be silently extracted when you unlock your system next time.

## What does it do?

This kit establishes following signature verification chain: UEFI Secure Boot -> Custom GRUB2 Image with your embedded verification keys -> Signed kernel, initramrs, grub config.

## How to use it?

Here is step by step guide:

### 1. Satisfy requirements

* x64 UEFI-enabled Linux installation
* grub2-efi-x64-modules
* grub2-tools
* sbsigntools
* efitools (https://git.kernel.org/pub/scm/linux/kernel/git/jejb/efitools.git). Later one is absent in Fedora repos, so you have to build it yourself. You'll need:
  * openssl-devel
  * gnu-efi-devel
  * perl-File-Slurp
  * help2man
  * Special patch for Make.rules to make it buildable, if you build it on Fedora. (Will be added shortly)

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
