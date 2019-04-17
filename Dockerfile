FROM alpine:edge
LABEL maintainer="Ferdinand Kasper <fkasper@modus-operandi.at>"

# COPY incompatibilities between Docker and Podman resolved in /usr/local/bin/build
COPY files/usr/local/bin/build /usr/local/bin/
COPY files /files/

RUN /usr/local/bin/build

VOLUME /var/www/localhost/public
VOLUME /var/www/localhost/var/sqlite

EXPOSE 80

ENTRYPOINT ["/usr/local/bin/entrypoint"]
CMD ["httpd", "-DFOREGROUND"]
