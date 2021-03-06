FROM alpine:3.10
LABEL maintainer="Ferdinand Kasper <fkasper@modus-operandi.at>"

ARG COMMIT
ARG IMAGE_VER=experimental
ARG TYPO3_VER=9.5

COPY files /
RUN /usr/local/bin/build

VOLUME /var/www/localhost

EXPOSE 80

ENTRYPOINT ["/usr/local/bin/init"]
CMD ["httpd", "-D", "FOREGROUND"]
STOPSIGNAL SIGHUP
