# Quick Start

### 1. Generate a PGP Key Pair

* Save the private key as `fs_protector_key.private.asc` in a USB memory for future key recovery.
* Save the public key to "example/fs_protector_key.public.asc".

### 2. Save SSH Key

* Store the SSH public key in `example/authorized_keys`.
* that will be used to back up the encrypted backup key

### 3. Build linuxkit image

```bash
$ linuxkit pkg build -network -org jclab pkg/securekit-sftpd
$ linuxkit pkg build -network -org jclab pkg/securekit-disk

$ cd example
$ ../securekit-build.sh example
$ ls -al
example-cmdline  example-initrd.img example-linux.efi
example-efi.iso  example-kernel     example.yml
```
