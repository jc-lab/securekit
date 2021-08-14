# Quick Start

### 1. Generate a PGP Key Pair

* Save the private key as `fs_protector_key.private.asc` in a USB memory for future key recovery.
* Save the public key to "example/fs_protector_key.public.asc".

### 2. Save SSH Key

* Store the SSH public key in `example/authorized_keys`.
* that will be used to back up the encrypted backup key

### 3. Prepare securekit script

```bash
$ cp scripts/efi-sign.sh.in scripts/efi-sign.sh
# Modify efi-sign.sh to sign efi
```

* Must have curl, objcopy and docker-buildx installed on your system.

### 4. Build linuxkit image

```bash
$ linuxkit pkg build -network -org jclab pkg/securekit-sshd
$ linuxkit pkg build -network -org jclab pkg/securekit-disk

$ cd example
$ ../scripts/securekit-build.sh example
$ ls -al
example-cmdline  example-initrd.img example-linux.efi
example-efi.iso  example-kernel     example.yml
```
