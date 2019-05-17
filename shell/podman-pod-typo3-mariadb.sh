#!/bin/sh

# Creates the pod and defines the exposed ports
podman pod create \
    --name typo3-pod \
    --publish 127.0.0.1:3306:3306 \
    --publish 127.0.0.1:8080:80 \
    --share net

# Starts the MariaDB container in the pod
podman run \
    --detach \
    --rm \
    --name mariadb \
    --pod typo3-pod \
    --env MARIADB_DATABASE=t3 \
    --env MARIADB_USER=t3 \
    --env MARIADB_PASSWORD=t3 \
    --env MARIADB_ROOT_PASSWORD=toor \
    --volume mariadb-vol:/bitnami/mariadb \
    bitnami/mariadb

# Starts the TYPO3 container in the pod
podman run \
    --detach \
    --rm \
    --name typo3 \
    --pod typo3-pod \
    --hostname dev.typo3.local \
    --env HOST_IP=$(hostname -I | awk '{print $1}') \
    --volume typo3-vol:/var/www/localhost \
    $@ \
    undecaf/typo3-dev
    