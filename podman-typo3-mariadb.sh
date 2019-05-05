#!/bin/sh

# Starts the MariaDB container, must expose HTTP port _now_ for later
podman run \
    --detach \
    --rm \
    --name mariadb \
    --env MARIADB_DATABASE=t3 \
    --env MARIADB_USER=t3 \
    --env MARIADB_PASSWORD=t3 \
    --env MARIADB_ROOT_PASSWORD=toor \
    --volume mariadb-vol:/bitnami/mariadb \
    --publish 127.0.0.1:3306:3306 \
    --publish 127.0.0.1:8080:80 \
    bitnami/mariadb

# Starts the TYPO3 container and joins the MariaDB network namespace
podman run \
    --detach \
    --rm \
    --volume typo3-vol:/var/www/localhost \
    --net container:mariadb \
    $@ \
    undecaf/typo3-dev
