# linux-secureboot-kit
Tool for complete hardening of Linux boot chain with UEFI Secure Boot. Inspired by [Hanno Heinrichs and Florent Hochwelker blog post](https://www.crowdstrike.com/blog/enhancing-secure-boot-chain-on-fedora-29/).

## Why?

Even if your hard disk is encrypted with full disk encryption, your bootloader config or initramdrive may be spoofed while you left your computer unattended. And this way your encryption key may be silently extracted when you unlock your system next time.

## What does it do?

This kit establishes following signature verification chain: UEFI Secure Boot -> Custom GRUB2 Image with your embedded verification keys -> Signed kernel, initramrs, grub config.

## Features

* Risk-free deployment. Old bootloader is retained after installation and it is possible to fallback to it at any time. If something went wrong just disable Secure Boot and choose original bootloader in your boot menu.
* No foreign code can be run on such protected machine, including live system images signed with vendor certificates.
* Support for automatic signature of DKMS-built modules.
* No MOK key enrollment required.

## How to use it?

Here is step by step guide:

### Step 1. Satisfy requirements

1. x64 UEFI-enabled Linux installation with GRUB2 bootloader
2. GRUB2 config without `blscfg` directives (they will fail boot since all files will have to be signed). Where applicable it is disabled automatically upon installation via `GRUB_ENABLE_BLSCFG="false"` variable in `/etc/default/grub`
3. GRUB2 tools and modules (`grub2-efi-x64-modules` and `grub2-tools` packages on RPM-based distros, Debian-based provides them by default)
4. sbsigntools (sbsigntool) 0.6+ (https://git.kernel.org/pub/scm/linux/kernel/git/jejb/sbsigntools.git/). If it is absent in your distro or too old, you have two options:
   * Use [static build](https://gist.github.com/Snawoot/a8f0863f362ed328b6bff00a3717f175). HEAD commit of this gist can be verified with [my PGP public key](https://keybase.io/yarmak/pgp_keys.asc). See install instructions in gist comment.
   * Build it yourself. You'll need:
     1. @development-tools (build-essential)
     2. openssl-devel (libssl-dev)
     3. libuuid-devel (uuid-dev)
     4. binutils-devel (binutils-dev)
5. efitools 1.9.2+ (https://git.kernel.org/pub/scm/linux/kernel/git/jejb/efitools.git). If it is absent in your distro or too old, you have two options:
   * Use [static build](https://gist.github.com/Snawoot/1937d5bc76d7b0a29f2039aa679c0449). HEAD commit of this gist can be verified with [my PGP public key](https://keybase.io/yarmak/pgp_keys.asc). See install instructions in gist comment.
   * Build it yourself. You'll need:
     1. @development-tools (build-essential)
     2. openssl-devel (libssl-dev)
     3. gnu-efi-devel (gnu-efi)
     4. perl-File-Slurp (libfile-slurp-perl)
     5. help2man

#### Fedora 30 hint

If you are building efitools on Fedora you'll need this [build script](https://gist.github.com/Snawoot/9cbad8a381b241c5bac5669d00f20620) to workaroud library paths issue.

### Step 2. Backup current UEFI keys

```
make backup
```

### Step 3. Clear your current UEFI keys (putting platform into Setup Mode)

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

### Step 4. Build keys, certificates, signed grub2 image and password hash for grub2 `root` user 

```
sudo make
```

Root access is required for proper embedded boot config generation. You will be asked for GRUB password during build process.

### Step 5. Install UEFI keys, bootloader and boot GPG signing keys

```
sudo make install
```

### Step 6. Sign all kernels, ramdrives and boot config

All new installed kernels, ramdrives and grub config has to be signed on update. Automation of this process may differ on various distros, but basicly all you have to do is generate detached signature with `gpg` like this:

```sh
FILE=/boot/vmlinuz-5.0.13-300.fc30.x86_64
gpg2 --quiet --no-permission-warning \
    --homedir /var/lib/secureboot/gpg-home \
    --detach-sign \
    --default-key "bootsigner@localhost" < "$FILE" > "$FILE.sig"
```

For some distros we already have such installable automation.

#### Fedora 30

```
sudo make fedora30-install
```

#### Debian 9, Debian 10

```
sudo make debian9-install
```

#### Ubuntu

```
sudo make ubuntu-install
```

#### Centos 7

```
sudo make centos7-install
```

Actually, you may just run single command with final target for your system and `make` will figure out which actions are pending. But step-by-step process is more explicit and easier to troubleshoot.

### Step 7. Lockdown your system

Ensure Secure Boot is enabled in your BIOS settings and administrator password is set. Set 'SignedBoot' UEFI boot entry as your first boot option.

## Notes

### DKMS and custom modules

Linux kernel in some distrubutions requires all modules to be signed with trusted signature when Secure Boot is enabled. Some distros (like Ubuntu) even offer mechanism for signing DKMS modules after build with enrolled MOK keys. Since we already own all platform keys, we don't need to enroll additional MOK keys into UEFI - we can sign modules with db keys instead. linux-secureboot-kit sets own hooks in order to supress signature with MOK keys and put it's own. Such hook chained after original DKMS source hooks via override file in `/etc/dkms`. Symlinks to override file created for every installed DKMS package upon linux-secureboot-kit setup. If you will install some new DKMS after linux-secureboot-kit setup, you have to create such symlink like this:

```bash
ln -s /var/lib/secureboot/dkms/chain-sign-hook.conf /etc/dkms/<package_name>.conf
```

or just re-run `setup_dkms.sh` script from this source directory. It'll add missing symlinks and initiate rebuild of unsigned modules.

If you are building modules manually, you may sign them with `/var/lib/secureboot/efi-keys/db.key` and `/var/lib/secureboot/efi-keys/db.der` using tool like `kmodsign` in Ubuntu or `scripts/sign_file` from kernel source directory (see [this issue](https://github.com/Snawoot/linux-secureboot-kit/issues/3) for example).
