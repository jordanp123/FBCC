FROM nginxinc/nginx-unprivileged:alpine-slim

# Copy the whole webroot read-only: every file lands 444 (read-only, no execute).
# --chmod applies that mode to directories too, which strips their traverse (x)
# bit, so the RUN below puts 0755 back on directories only. Without it the
# non-root runtime user (uid 7001, see docker-compose.yaml) can't traverse into
# subdirectories like /assets and every request there 403s (unstyled site,
# broken images).
#
# --chown=0:0 is the COPY default (stated explicitly); combined with the non-root
# runtime user and the read-only rootfs, the nginx worker can read the webroot
# but never modify it. Requires BuildKit for --chmod (default on modern Docker).
COPY --chown=0:0 --chmod=444 files/ /usr/share/nginx/html/

# Files keep 444; directories get 0755 so uid 7001 can traverse the tree.
# Needs root for the chmod (the base image runs as the nginx user), then drop back.
USER root
RUN find /usr/share/nginx/html -type d -exec chmod 0755 {} +
USER nginx

# ── nginx config (separate destination, so a separate COPY) ──
COPY --chown=0:0 --chmod=444 nginx.conf /etc/nginx/conf.d/default.conf
