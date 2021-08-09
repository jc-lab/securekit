FROM linuxkit/alpine:5b64d3506f3bc3aa4bcbb32a107ca138f41826e2 AS builder
RUN apk add \
    build-base abuild autoconf automake cmake \
    curl libtool perl python3 file tar xz \
    libc-dev openssl-dev zlib-dev \
    linux-headers util-linux-dev

RUN mkdir -p /work/aports /out

RUN mkdir -p ~/.abuild && \
    echo "PACKAGER=alpine-package@justnow.com" | tee ~/.abuild/abuild.conf && \
    abuild-keygen -a -i -q -n && \
    cp /root/.abuild/alpine-package@justnow.com-*.pub /etc/apk/keys/

COPY [ "aports/curl", "/work/aports/curl" ]
RUN ln -s `which python3` /usr/bin/python && \
    cd /work/aports/curl && \
    abuild -F

COPY [ "aports/json-c", "/work/aports/json-c" ]
RUN cd /work/aports/json-c && \
    abuild -F

RUN cd ~/packages/aports/`uname -m`/ && \
    apk add libcurl-*.apk && \
    apk add curl-dev-*.apk && \
    apk add json-c-dev-*.apk

ARG AUTOCONF_ARCHIVE_URL=http://mirror.yongbok.net/gnu/autoconf-archive/autoconf-archive-2021.02.19.tar.xz
ARG AUTOCONF_ARCHIVE_HASH=e8a6eb9d28ddcba8ffef3fa211653239e9bf239aba6a01a6b7cfc7ceaec69cbd
RUN cd /work && \
    curl -L -o autoconf-archive.tar.xz ${AUTOCONF_ARCHIVE_URL} && \
    echo "${AUTOCONF_ARCHIVE_HASH}  autoconf-archive.tar.xz" | sha256sum -c && \
    mkdir -p autoconf-archive && \
    cd autoconf-archive && \
    tar --strip-components 1 -xf ../autoconf-archive.tar.xz && \
    ./configure --prefix=/usr && \
    make && make install

COPY [ "aports/tpm2-tss", "/work/aports/tpm2-tss" ]
RUN cd /work/aports/tpm2-tss && \
    abuild -F

RUN cd ~/packages/aports/`uname -m`/ && \
    apk add tpm2-tss-*.apk

COPY [ "aports/tpm2-tools", "/work/aports/tpm2-tools" ]
RUN cd /work/aports/tpm2-tools && \
    abuild -F

RUN mkdir -p /work/packages && \
    cp /etc/apk/keys/alpine-package@justnow.com-*.pub /work/packages/ && \
    cd ~/packages/aports/`uname -m` && \
    for name in $(find . -type f -name "*.apk" | grep -v -E "(-dev-|-static-|-doc-|-dbg-)"); do cp "$name" /work/packages/; done

# alpine:3.13 amd64
FROM alpine@sha256:def822f9851ca422481ec6fee59a9966f12b351c62ccb9aca841526ffaa9f748 as sequoia
RUN apk update && \
    apk add \
    bash git cargo patch \
    sqlite-dev openssl-dev nettle-dev clang-dev
RUN mkdir -p /work && \
    cd /work && \
    git clone https://gitlab.com/sequoia-pgp/sequoia.git && \
    cd sequoia && \
    git checkout -f 7bde618ccdd7d03cdb115f558e919219b0910319
COPY [ "sq-decrypt-stdin.patch", "/work/sequoia/" ]
RUN cd /work/sequoia && \
    patch -p1 < sq-decrypt-stdin.patch && \
    CARGO_TARGET_DIR=target cargo build -p sequoia-sq --release && \
    install --strip -D --target-directory /out/usr/bin \
    target/release/sq

FROM linuxkit/alpine:5b64d3506f3bc3aa4bcbb32a107ca138f41826e2 AS mirror
RUN mkdir -p /out/etc/apk && cp -r /etc/apk/* /out/etc/apk/
RUN apk add --no-cache --initdb -p /out  \
    alpine-baselayout \
    bash \
    cryptsetup \
    e2fsprogs \
    sfdisk \
    util-linux \
    gnupg \
    libgcc

COPY --from=builder "/work/packages" "/packages"

RUN cp /packages/alpine-package@justnow.com-*.pub /etc/apk/keys/ && \
    ls -al /packages/ && \
    apk add --no-cache --initdb -p /out --allow-untrusted \
    /packages/curl-*.apk && \
    apk add --no-cache --initdb -p /out --allow-untrusted \
    /packages/json-c-*.apk && \
    apk add --no-cache --initdb -p /out --allow-untrusted \
    /packages/tpm2-tss-*.apk && \
    apk add --no-cache --initdb -p /out --allow-untrusted \
    /packages/tpm2-tools-*.apk

ADD "opt/" "/out/opt/"
COPY "sshd_config" "/out/etc/ssh/sshd_config"

# Remove apk residuals
# Cleanup
RUN rm -rf /out/etc/apk /out/lib/apk /out/var/cache && \
    rm -rf /out/usr/share && \
    rm -rf /out/usr/include && \
    find /out/opt/securekit/ -type f -name "*.sh" | grep 'bin/' | xargs chmod 555

FROM scratch
ENTRYPOINT []
WORKDIR /
COPY --from=mirror /out/ /
COPY --from=sequoia /out/ /
RUN adduser -s /opt/securekit/bin/remote-shell.sh -D manager && \
    mkdir -p /home/manager/.ssh && \
    chown manager:manager -R /home/manager/ && \
    sed -i -e 's/manager:!/manager:*/g' /etc/shadow

# SEE https://github.com/linuxkit/linuxkit/blob/master/pkg/dm-crypt/crypto.sh
# https://en.opensuse.org/Software_TPM_Emulator_For_QEMU
# https://tpm2-software.github.io/2020/04/13/Disk-Encryption.html
