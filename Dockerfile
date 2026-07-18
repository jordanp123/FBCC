FROM nginxinc/nginx-unprivileged:alpine

COPY files/ /usr/share/nginx/html/
COPY nginx.conf /etc/nginx/conf.d/default.conf
