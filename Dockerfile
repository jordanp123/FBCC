FROM nginxinc/nginx-unprivileged:alpine-slim

# Files are copied individually so each can be mode 444 (read-only, no execute).
# A single `COPY files/ ...` can't do this: --chmod applies one mode to files AND
# directories, and 444 on a directory strips the traversal bit (breaks asset
# serving). Copying file-by-file lets Docker auto-create the parent dirs as
# 0755 (traversable) while the files themselves stay 444.
#
# --chown=0:0 is the COPY default (stated explicitly); combined with the non-root
# runtime user (see docker-compose.yaml) and the read-only rootfs, the nginx
# worker can read the webroot but never modify it.
#
# NOTE: adding a new file under files/ means adding a COPY line here, or it won't
# be served. Requires BuildKit for --chmod (default on modern Docker).

# ── Site pages ──
COPY --chown=0:0 --chmod=444 files/index.html     /usr/share/nginx/html/index.html
COPY --chown=0:0 --chmod=444 files/services.html  /usr/share/nginx/html/services.html
COPY --chown=0:0 --chmod=444 files/location.html  /usr/share/nginx/html/location.html
COPY --chown=0:0 --chmod=444 files/bulletin.html  /usr/share/nginx/html/bulletin.html
COPY --chown=0:0 --chmod=444 files/events.html    /usr/share/nginx/html/events.html
COPY --chown=0:0 --chmod=444 files/contact.html   /usr/share/nginx/html/contact.html
COPY --chown=0:0 --chmod=444 files/give.html      /usr/share/nginx/html/give.html
COPY --chown=0:0 --chmod=444 files/404.html       /usr/share/nginx/html/404.html

# ── Crawler files ──
COPY --chown=0:0 --chmod=444 files/robots.txt     /usr/share/nginx/html/robots.txt
COPY --chown=0:0 --chmod=444 files/sitemap.xml    /usr/share/nginx/html/sitemap.xml

# ── Assets ──
COPY --chown=0:0 --chmod=444 files/assets/css/style.css            /usr/share/nginx/html/assets/css/style.css
COPY --chown=0:0 --chmod=444 files/assets/images/pastor-family.jpg /usr/share/nginx/html/assets/images/pastor-family.jpg
COPY --chown=0:0 --chmod=444 files/assets/images/sanctuary.webp    /usr/share/nginx/html/assets/images/sanctuary.webp

# ── nginx config ──
COPY --chown=0:0 --chmod=444 nginx.conf /etc/nginx/conf.d/default.conf
