FROM linuxkit/alpine:5b64d3506f3bc3aa4bcbb32a107ca138f41826e2 AS mirror
RUN mkdir -p /out/etc/apk && cp -r /etc/apk/* /out/etc/apk/
RUN apk add --no-cache --initdb -p /out  \
    alpine-baselayout \
    busybox \
    bash

# Remove apk residuals
RUN rm -rf /out/etc/apk /out/lib/apk /out/var/cache

FROM scratch
WORKDIR /
COPY --from=mirror /out/ /
COPY ["log2console.sh", "/log2console.sh"]
RUN chmod +x /log2console.sh
CMD ["/log2console.sh"]
