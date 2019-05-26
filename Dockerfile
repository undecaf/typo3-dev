FROM alpine:3.9
LABEL maintainer="Ferdinand Kasper <fkasper@modus-operandi.at>"

ARG IMAGE_VER=experimental
ARG TYPO3_VER=9.5

COPY files /
RUN /usr/local/bin/build

VOLUME /var/www/localhost

EXPOSE 80

ENTRYPOINT ["/usr/local/bin/init"]
CMD ["/usr/local/bin/start-apache"]
STOPSIGNAL SIGHUP
