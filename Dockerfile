FROM nginxinc/nginx-unprivileged:alpine

COPY files/*.html /usr/share/nginx/html/
COPY files/assets/ /usr/share/nginx/html/assets/
COPY files/nginx.conf /etc/nginx/conf.d/default.conf
