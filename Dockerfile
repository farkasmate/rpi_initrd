ARG ALPINE_VERSION=latest
FROM alpine:${ALPINE_VERSION} as BUILD

ARG KERNEL_PKG=linux-lts

WORKDIR /build/

ADD init initrd/init

RUN echo '@v3.10 http://dl-cdn.alpinelinux.org/alpine/v3.10/main' >> /etc/apk/repositories \
    && \
    apk add --update \
      open-iscsi@v3.10 \
      tar \
    && \
    apk fetch \
      busybox \
      ${KERNEL_PKG} \
    && \
    tar xf busybox-*.apk bin/busybox && \
    tar xf ${KERNEL_PKG}-*.apk --wildcards \
      boot/vmlinuz-* \
      lib/modules/*/kernel/drivers/scsi/iscsi_tcp.ko \
      lib/modules/*/kernel/drivers/scsi/libiscsi.ko \
      lib/modules/*/kernel/drivers/scsi/libiscsi_tcp.ko \
    && \
    mkdir -p initrd/bin initrd/lib/modules && \
    cp -a bin/busybox initrd/bin/busybox && \
    cp -a /sbin/iscsistart initrd/bin/iscsistart && \
    ln -s busybox initrd/bin/sh && \
    cp -a /lib/ld-musl-*.so.1 initrd/lib/ && \
    cp -a lib/modules/*/kernel/drivers/scsi/* initrd/lib/modules/ \
    && \
    cd initrd && \
    find . | cpio --quiet -R 0:0 -o -H newc | gzip > ../initrd.cpio.gz

FROM alpine:${ALPINE_VERSION} as DEPLOY

WORKDIR /artifacts/

COPY --from=BUILD /build/initrd.cpio.gz .
COPY --from=BUILD /build/boot/vmlinuz-* kernel8.img

CMD echo '[FIXME] Deploying initrd'
