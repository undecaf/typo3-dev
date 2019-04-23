FROM alpine
LABEL maintainer="Ferdinand Kasper <fkasper@modus-operandi.at>"

COPY files /
RUN /usr/local/bin/build

VOLUME /var/www/localhost/public
VOLUME /var/www/localhost/var/sqlite

EXPOSE 80

ENTRYPOINT ["/usr/local/bin/entrypoint"]
CMD ["httpd", "-DFOREGROUND"]
