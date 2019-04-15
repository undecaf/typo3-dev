FROM alpine:edge
LABEL maintainer="Ferdinand Kasper <fkasper@modus-operandi.at>"

COPY etc root usr var /
RUN /usr/local/bin/build

VOLUME /var/www/localhost/public

EXPOSE 80 22
ENTRYPOINT ["/usr/local/bin/entrypoint"]
