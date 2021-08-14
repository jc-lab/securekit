FROM linuxkit/alpine:5b64d3506f3bc3aa4bcbb32a107ca138f41826e2 AS mirror
RUN mkdir -p /out/etc/apk && cp -r /etc/apk/* /out/etc/apk/
RUN apk add --no-cache --initdb -p /out  \
    alpine-baselayout \
    busybox \
    ca-certificates \
    musl \
    tini \
    util-linux \
    zlib openssl \
    bash

# Remove apk residuals
RUN rm -rf /out/etc/apk /out/lib/apk /out/var/cache

FROM linuxkit/alpine:5b64d3506f3bc3aa4bcbb32a107ca138f41826e2 AS builder
RUN apk add \
    curl gcc make libc-dev openssl-dev zlib-dev file patch

RUN mkdir -p /work/patches /out

COPY [ "*.patch", "/work/patches/" ]
RUN cd /work/patches && echo $'\
289dcc0537af3e3d623226278f58e756a33b6015d8ac8325421642f80f62c16d  disable-forwarding-by-default.patch\n\
1c85437fd94aa4fc269e6297e4eb790baa98c39949ec0410792c09ee31ba9782  fix-utmp.patch\n\
3638f1b7969d49934130479835167250fb18f61a198593f3c0c5254089bbbb53  fix-verify-dns-segfault.patch\n\
4ce1ad5f767c0f4e854a0cfeef0e2e400f333c649e552df1ecc317e6a6557376  sftp-interactive.patch\
' | sha256sum -c

ARG OPENSSH_URL=https://ftp.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-8.6p1.tar.gz
ARG OPENSSH_HASH=c3e6e4da1621762c850d03b47eed1e48dff4cc9608ddeb547202a234df8ed7ae
RUN mkdir -p /work/openssh && \
    cd /work && \
    curl -L ${OPENSSH_URL} -o openssh.tar.gz && \
    echo "${OPENSSH_HASH}  openssh.tar.gz" | sha256sum -c && \
    cd openssh && \
    tar --strip-components 1 -zxf ../openssh.tar.gz && \
    (for name in $(find /work/patches -type f -name "*.patch"); do patch -p1 < $name; done) && \
    ./configure \
		--build=`uname -m` \
		--host=`uname -m` \
		--prefix=/usr \
		--sysconfdir=/etc/ssh \
		--libexecdir=/usr/lib/ssh \
		--mandir=/usr/share/man \
		--with-pid-dir=/run \
		--with-mantype=doc \
		--disable-lastlog \
		--disable-strip \
		--disable-wtmp \
		--with-privsep-path=/var/empty \
		--with-xauth=/usr/bin/xauth \
		--with-privsep-user=sshd \
		--with-md5-passwords \
		--with-ssl-engine \
    make
RUN cd /work/openssh && make install DESTDIR=/out

FROM scratch
ENTRYPOINT []
WORKDIR /
COPY --from=mirror /out/ /
COPY --from=builder /out/ /
COPY etc/ /etc/
COPY usr/ /usr/
RUN adduser -u 1002 -s /bin/bash -D manager && \
    mkdir -m 700 -p /home/manager/.ssh && \
    chown manager:manager -R /home/manager && \
    chmod 700 /home/manager && \
    mkdir -p /etc/ssh /var/empty && \
    chmod +x /usr/bin/*.sh

CMD ["/sbin/tini", "/usr/bin/ssh.sh"]
