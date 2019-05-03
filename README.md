# Developing for TYPO3 with Docker or Podman

Provides a containerized TYPO3 installation equivalent to
[`composer require typo3/cms`](https://packagist.org/packages/typo3/cms) with
[ImageMagick](https://www.imagemagick.org/) and configured for
[Composer Mode](https://wiki.typo3.org/Composer#Composer_Mode).

Such a TYPO3 container can be linked to a
[MySQL or a PostgreSQL container](#using-mariadb-or-postgresql)
but can be run also independenty owing to the built-in SQLite database.

You may use your favorite IDE on the host to work on TYPO3 in the container.
File access rights, ownerships, UIDs and GIDs are transparently and consistently
mapped between host and container.

## Contents

-   [Building the image](#building-the-image)
-   [Running TYPO3](#running-typo3)
    -   [TL;DR (quick & dirty)](#tldr-quick--dirty)
    -   [Using MariaDB or PostgreSQL](#using-mariadb-or-postgresql)
        -   [Docker Compose](#docker-compose)
        -   [Podman](#podman)
        -   [Podman pod](#podman-pod)
    -   [Volumes](#volumes)
    -   [Runtime configuration](#runtime-configuration)
-   [Developing](#developing)
    -   [Shell access and `composer`](#shell-access-and-composer)
    -   [Using your favorite IDE](#using-your-favorite-ide)
        -   [Preparation](#preparation)
        -   [Developing](#developing-1)
        -   [Debugging](#debugging)
        -   [Cleaning up](#cleaning-up)
    -   [Accessing the TYPO3 database](#accessing-the-typo3-database)
-   [Licenses](#licenses)

## Building the image

In order to build the image with [Docker](https://www.docker.com/) and name it
`localhost/typo3-dev`:

```bash
$ docker build \
    --tag localhost/typo3-dev \
    git://github.com/undecaf/typo3-dev
```

The resulting image is based on [Alpine Linux](https://alpinelinux.org/), Apache and
PHP&nbsp;7 and is quite compact (280&nbsp;MB).

If you prefer
[working rootless](https://de.slideshare.net/AkihiroSuda/rootless-containers)
with [Podman](https://podman.io/) then substitute `podman` for `docker` 
where applicable, or simply set `alias docker=podman`.


## Running TYPO3

### TL;DR (quick & dirty)

For a TYPO3 instance in a standalone container, do this:
```bash
$ docker run \
    --detach \
    --rm \
    --hostname dev.typo3.local \
    --volume sqlite-vol:/var/www/localhost/var/sqlite \
    --volume typo3-vol:/var/www/localhost/public \
    --publish 127.0.0.1:8080:80 \
    localhost/typo3-dev
```

Next, browse to `http://localhost:8080`. This starts the TYPO3 installation wizard. 
When asked to select a database, choose `Manually configured SQLite connection` and
continue through the remaining dialogs to the TYPO3 login dialog.

[Volumes](#volumes) `sqlite-vol` and `typo3-vol` provide
convenient host access to the SQLite database and to the TYPO3
installation.

### Using MariaDB or PostgreSQL

The following example shows how to employ MariaDB
([`bitnami/mariadb`](https://hub.docker.com/r/bitnami/mariadb)) as TYPO3
database.
Working with PostgreSQL ([`bitnami/postgresql`](https://hub.docker.com/r/bitnami/postgresql)) is very similar&nbsp;&ndash; please refer to the 
[documentation on Docker Hub](https://hub.docker.com/r/bitnami/postgresql#creating-a-database-on-first-run)
for a quick start.

#### Docker Compose

TODO: docker-compose file

#### Podman

Starting the database and TYPO3 containers separately but with a shared network
stack: `127.0.0.1` is shared _between_ containers but is separate from the host's
`127.0.0.1`.

```bash
## Starts the MariaDB container, must expose HTTP port _now_ for later
$ podman run \
    --detach \
    --name mariadb \
    --env MARIADB_DATABASE=t3 \
    --env MARIADB_USER=t3 \
    --env MARIADB_PASSWORD=t3 \
    --env MARIADB_ROOT_PASSWORD=toor \
    --volume mariadb-vol:/bitnami/mariadb \
    --publish 127.0.0.1:3306:3306 \
    --publish 127.0.0.1:8080:80 \
    bitnami/mariadb

## Starts the TYPO3 container and joins the MariaDB network namespace
$ podman run \
    --detach \
    --rm \
    --hostname dev.typo3.local \
    --volume typo3-vol:/var/www/localhost/public \
    --net container:mariadb \
    localhost/typo3-dev
```

#### Podman pod

Podman can group the TYPO3 and the database container in a pod which then can be
managed as a unit:

```bash
## Creates the pod and defines the exposed ports
$ podman pod create \
    --name typo3-pod \
    --publish 127.0.0.1:3306:3306 \
    --publish 127.0.0.1:8080:80 \
    --share net

## Starts the MariaDB container in the pod
$ podman run \
    --detach \
    --name mariadb \
    --pod typo3-pod \
    --env MARIADB_DATABASE=t3 \
    --env MARIADB_USER=t3 \
    --env MARIADB_PASSWORD=t3 \
    --env MARIADB_ROOT_PASSWORD=toor \
    --volume mariadb-vol:/bitnami/mariadb \
    bitnami/mariadb

## Starts the TYPO3 container in the pod
podman run \
    --detach \
    --name typo3 \
    --pod typo3-pod \
    --hostname dev.typo3.local \
    --volume typo3-vol:/var/www/localhost/public \
    localhost/typo3-dev
```

The pod can be stopped and restarted as a unit:
```bash
## Stops the pod
$ podman pod stop typo3-pod

## (Re-)Starts the pod
$ podman pod start typo3-pod
```

### Volumes

Volumes can be attached to the following container paths for
convenient host access to the container state: 

-   `/var/www/localhost/public`: TYPO3 document root. Note that
    `composer.json` is located in the parent directory and can be accessed only [through a container shell](#shell-access-and-composer).
-   `/var/www/localhost/var/sqlite`: contains the TYPO3 SQLite database, otherwise
    empty.
-   `/bitnami/mariadb`: contains the MariaDB database, otherwise not available.
-   `/bitnami/postgresql`: contains the PostgreSQL database, otherwise not available.

### Runtime configuration

##### `--hostname`

Determines both the container hostname and the Apache `ServerName` and `ServerAdmin`.
If `--hostname` is omitted then the container gets a random hostname, and `ServerName` 
defaults to `localhost`.

##### Environment variables

May be set not only as `--env` variables in `docker run` but can also be changed afterwards in a _running_ container like so:
```bash
$ docker exec <container-id> setenv var=value ...
```

-   `TIMEZONE`: sets the container timezone (e.g. `Europe/Vienna`), defaults to UTC.

-   `MODE`:
    -   `dev` selects development mode, i.e. TYPO3 in „Development Mode“, 
        verbose Apache/PHP signature headers, PHP settings as recommended by
        [`php.ini-development`](https://github.com/php/php-src/blob/master/php.ini-development)
    -   `xdebug` selects development mode as above and enables 
        [XDebug](https://xdebug.org/)
    -   `prod` selects production mode: TYPO3 in „Production Mode“, no Apache/PHP
        signature headers, PHP settings as per
        [`php.ini-production`](https://github.com/php/php-src/blob/master/php.ini-production)

-   `PHP_...`: environment variables prefixed with `PHP_` or `php_` become `php.ini`
    settings with the prefix removed, e.g. `--env php_post_max_size=5M` becomes 
    `post_max_size=5M`. These settings override prior settings and `MODE`.


## Developing

### Shell access and `composer`

In order to manage the TYPO3 installation with
[Composer](https://wiki.typo3.org/Composer), shell access in the container
is required. To open a `root` shell in a running container:
```bash
$ docker exec -it <container-id> bash
root@dev.typo3.local:/# 
```

You may now run `composer` from within the container root shell.
The container's `composer` command has been customized for TYPO3 packages so that:
-   `composer` always uses `/var/www/localhost` as working directory
    (i.e. the location of `composer.json` for TYPO3), 
    even if the command is run in a different directory;
-   directories and files created by `composer` are owned by the Apache daemon
    although the command is run by `root`.

Thus, `composer` guarantees that packages will be installed at the correct locations
and with correct ownership.

Note that neither `composer` nor PHP have to be installed on the host.

### Using your favorite IDE

The TYPO3 installation is accessible outside of the 
container at the mount point of `typo3-vol`. However, UIDs and GIDs have been
mapped into user namespace and therefore are different from your own ones:
```bash
$ ls -lA $(docker volume inspect --format '{{.MountPoint}}' typo3-vol)

drwxrwsr-x 4 100999 100100  4096 Apr 17 00:01 fileadmin
-rw-rw-r-- 1 100999 100100 13770 Apr 18 21:37 .htaccess
-rw-r--r-- 1 100999 100100   955 Apr 18 00:22 index.php
drwxr-xr-x 3 100999 100100  4096 Apr 16 16:26 typo3
drwxrwsr-x 4 100999 100100  4096 Apr 22 17:55 typo3conf
drwxrwsr-x 4 100999 100100  4096 Apr 17 00:01 typo3temp
```

Fortunately, there is [bindfs](https://bindfs.org/) (available for Debian-like OSs
and for MacOS): it can provide a bind-mounted view of these files and directories
with their UIDs and GIDs mapped to your UID and GID.

#### Preparation

First, you have to create a mountpoint for such a view. In order to
keep IDE settings out of the TYPO3 document root, this should be a
_subdirectory_ of your envisaged TYPO3 development directory :
```bash
$ T3_DEV_DOCROOT=~/typo3-dev/docroot

$ mkdir -p $T3_DEV_DOCROOT
```

Now have bindfs mount the `typo3-vol` directory at `$T3_DEV_DOCROOT` with your
UID and GID:
```bash
$ T3_VOL=$(docker volume inspect --format '{{.MountPoint}}' typo3-vol)
$ T3_UID=$(stat --format '%u' $T3_VOL/index.php)
$ T3_GID=$(stat --format '%g' $T3_VOL/index.php)

$ sudo bindfs \
    --map=$T3_UID/$(id -u):@$T3_GID/@$(id -g) \
    $T3_VOL \
    $T3_DEV_DOCROOT

## UIDs and GIDs mapped to the current user's UID and GID
$ ls -nA $T3_DEV_DOCROOT

drwxrwsr-x 4 1000 1000  4096 Apr 17 00:01 fileadmin
-rw-rw-r-- 1 1000 1000 13770 Apr 18 21:37 .htaccess
-rw-r--r-- 1 1000 1000   955 Apr 18 00:22 index.php
drwxr-xr-x 3 1000 1000  4096 Apr 16 16:26 typo3
drwxrwsr-x 4 1000 1000  4096 Apr 22 17:55 typo3conf
drwxrwsr-x 4 1000 1000  4096 Apr 17 00:01 typo3temp
```

#### Developing

Open the _parent directory_ of `$T3_DEV_DOCROOT` with your favorite IDE, e.g.
```bash
$ code $T3_DEV_DOCROOT/..
```
Any changes
you make in your IDE will be propagated to the running container automagically.

#### Debugging

TODO

#### Cleaning up

To clean up afterwards:
```bash
$ sudo umount $T3_DEV_DOCROOT
```

### Accessing the TYPO3 database

TODO

## Podman pods

To use this image directly, you can use a docker-compose file to keep things nice and simple... if you have a load balancer like traefik and mysql containers running on another docker network, you may have something like this...


```yml
version: "2"
services:
  myservice:
    build: ./
    labels:
      - "traefik.backend=myservice"
      - "traefik.frontend.rule=Host:myservice.docker.localhost"
    environment:
      - MYSQL_HOST=mysql
      - APACHE_SERVER_NAME=myservice.docker.localhost
      - PHP_SHORT_OPEN_TAG=On
      - PHP_ERROR_REPORTING=E_ALL
      - PHP_DISPLAY_ERRORS=On
      - PHP_HTML_ERRORS=On
      - PHP_XDEBUG_ENABLED=true
    networks:
      - default
    volumes:
      - ./:/app
  # ADD in permission for setting system time to host system time
    cap_add:
      - SYS_TIME
      - SYS_NICE
networks:
  default:
    external:
      name: docker_docker-localhost
```

Then run...

```bash
docker-compose up -d
```

This will patch the container through to traefik load balancer running from another dc file.

If you would like to add to this, expand on this, maybe you don't want to map your volume and want to copy files for a production system. You can create your own Dockerfile based on this image...

```bash
FROM ulsmith/alpine-apache-php7
MAINTAINER You <you@youremail.com>

ADD /public /app/public
RUN chown -R apache:apache /app
```

## Licenses

Scripts in this repository are licensed under the GPL&nbsp;3.0.
This document is licensed under the Creative Commons license CC&nbsp;BY-SA&nbsp;3.0.
For licenses regarding container images, please refer to 
[this discussion](https://opensource.stackexchange.com/questions/7013/license-for-docker-images#answer-7015).
