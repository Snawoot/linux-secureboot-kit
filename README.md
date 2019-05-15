# linux-secureboot-kit
Tool for complete hardening of Linux boot chain with UEFI Secure Boot. Inspired by [Hanno Heinrichs and Florent Hochwelker blog post](https://www.crowdstrike.com/blog/enhancing-secure-boot-chain-on-fedora-29/).

## Why?

Even if your hard disk is encrypted with full disk encryption, your bootloader config or initramdrive may be spoofed while you left your computer unattended. And this way your encryption key may be silently extracted when you unlock your system next time.

## What does it do?

This kit establishes following signature verification chain: UEFI Secure Boot -> Custom GRUB2 Image with your embedded verification keys -> Signed kernel, initramrs, grub config.

## How to use it?

Here is step by step guide:

### Step 1. Satisfy requirements

1. x64 UEFI-enabled Linux installation with GRUB2 bootloader
2. GRUB2 config without `blscfg` directives (they will fail boot since all files will have to be signed). Where applicable it is disabled automatically upon installation via `GRUB_ENABLE_BLSCFG="false"` variable in `/etc/default/grub`
3. GRUB2 tools and modules (grub2-efi-x64-modules and grub2-tools on RPM-based distros, Debian-based provides them by default)
4. sbsigntools (sbsigntool)
5. efitools 1.9.2+ (https://git.kernel.org/pub/scm/linux/kernel/git/jejb/efitools.git). If it is absent in your distro or too old, you have two options:
   * Use [static build](https://gist.github.com/Snawoot/1937d5bc76d7b0a29f2039aa679c0449). HEAD commit of this gist can be verified with [my PGP public key](https://keybase.io/yarmak/pgp_keys.asc).
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

#### Debian 9 and Debian 10 notes

Debian requires slightly different set of modules to build GRUB2 image. For this case use following build command:

```
sudo make GRUB2EXTRAMODULES=linuxefi
```

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

### Step 7. Lockdown your system

Ensure Secure Boot is enabled in your BIOS settings and administrator password is set. Set 'SignedBoot' UEFI boot entry as your first boot option.
