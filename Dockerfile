FROM alpine:3.9
LABEL maintainer="Ferdinand Kasper <fkasper@modus-operandi.at>"

COPY files /
RUN /usr/local/bin/build

VOLUME /var/www/localhost

EXPOSE 80 81 85 25

ENTRYPOINT ["/usr/local/bin/init"]
CMD ["httpd", "-D", "FOREGROUND"]
