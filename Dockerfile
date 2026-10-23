FROM alpine:3.24

# iptables is only used by wg-quick for full-tunnel configs (AllowedIPs = 0.0.0.0/0).
RUN apk add --no-cache wireguard-tools iptables && adduser -D -u 1000 user

COPY --chmod=755 entrypoint resolvconf healthcheck /usr/local/bin/

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 CMD ["/usr/local/bin/healthcheck"]

STOPSIGNAL SIGTERM

ENTRYPOINT ["/usr/local/bin/entrypoint"]
