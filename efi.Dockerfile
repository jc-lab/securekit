FROM alpine:3.13 as builder

RUN apk update && \
    apk add \
    bash git make gcc binutils file libc-dev gnu-efi-dev \
    mtools xorriso

RUN mkdir -p /work && \
    cd /work && \
    git clone https://github.com/jclab-joseph/systemd-boot-efi.git && \
    cd systemd-boot-efi && \
    git checkout -f df46b36800cc5249a302694b21d80438f6bf8c7f && \
    git submodule update --init

RUN cd /work/systemd-boot-efi && \
    make

ARG IMAGE_NAME
COPY ["${IMAGE_NAME}-cmdline", "${IMAGE_NAME}-kernel", "${IMAGE_NAME}-initrd.img", "/work/"]

RUN objcopy \
    --add-section .osrel="/etc/os-release" --change-section-vma .osrel=0x20000 \
    --add-section .cmdline="/work/${IMAGE_NAME}-cmdline" --change-section-vma .cmdline=0x30000 \
    --add-section .linux="/work/${IMAGE_NAME}-kernel" --change-section-vma .linux=0x2000000 \
    --add-section .initrd="/work/${IMAGE_NAME}-initrd.img" --change-section-vma .initrd=0x3000000 \
    /work/systemd-boot-efi/linuxx64.efi.stub "/work/${IMAGE_NAME}-linux.efi"

RUN mkdir -p /work/iso/boot && \
    dd if=/dev/zero of=/work/iso/boot/efiboot.img bs=1M count=384 && \
    mkfs.vfat /work/iso/boot/efiboot.img && \
    mmd -i /work/iso/boot/efiboot.img efi efi/boot && \
    mcopy -vi /work/iso/boot/efiboot.img \
              /work/${IMAGE_NAME}-linux.efi ::efi/boot/bootx64.efi && \
    xorriso \
    -as mkisofs \
    -iso-level 3 \
    -o "/work/${IMAGE_NAME}-efi.iso" \
    -full-iso9660-filenames \
    -volid "${IMAGE_NAME}" \
    -eltorito-alt-boot \
        -e /boot/efiboot.img \
        -no-emul-boot \
        -isohybrid-gpt-basdat \
    -append_partition 2 0xef /work/iso/boot/efiboot.img \
    "/work/iso"

FROM scratch
ARG IMAGE_NAME
COPY --from=builder ["/work/${IMAGE_NAME}-linux.efi", "/work/${IMAGE_NAME}-efi.iso", "/"]

