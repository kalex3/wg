FROM alpine:3.24.4 AS rootfs

# Install into an empty root so the final image has no package manager, no
# OpenSSL and no CA bundle. The package database stays in /lib/apk so image
# scanners can still list what is installed.
# Only the wg binary and a minimal ip: the entrypoint replaces wg-quick, so
# bash is not needed. iptables is only used for full-tunnel configs
# (AllowedIPs = 0.0.0.0/0) and for PostUp/PreDown hooks that call it.
RUN apk add --no-cache --root /rootfs --initdb \
        --keys-dir /etc/apk/keys --repositories-file /etc/apk/repositories \
        alpine-baselayout busybox busybox-binsh wireguard-tools-wg iproute2-minimal iptables

FROM scratch

COPY --from=rootfs /rootfs/ /
COPY --chmod=755 entrypoint healthcheck /usr/local/bin/

HEALTHCHECK CMD ["/usr/local/bin/healthcheck"]

STOPSIGNAL SIGTERM

ENTRYPOINT ["/usr/local/bin/entrypoint"]
