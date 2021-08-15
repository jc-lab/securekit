FROM alpine:3.13 as builder

RUN apk update && \
    apk add \
    bash \
    mtools xorriso

ARG IMAGE_NAME
COPY ["${IMAGE_NAME}-linux.efi", "/work/"]

RUN mkdir -p /work/iso/boot && \
    efi_file_size=$(stat -c %s "/work/${IMAGE_NAME}-linux.efi") && \
    efi_part_size=$((efi_file_size / 1024 / 1024 + 32)) && \
    dd if=/dev/zero of=/work/iso/boot/efiboot.img bs=1M count=${efi_part_size} && \
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
COPY --from=builder ["/work/${IMAGE_NAME}-efi.iso", "/"]

