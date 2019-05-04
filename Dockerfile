FROM alpine:3.9
LABEL maintainer="Ferdinand Kasper <fkasper@modus-operandi.at>"

COPY files /
RUN /usr/local/bin/build

VOLUME /var/www/localhost

EXPOSE 80

ENTRYPOINT ["/usr/local/bin/init"]
CMD ["httpd", "-D", "FOREGROUND"]
