# Developing for TYPO3 with Docker or Podman

This project provides a containerized TYPO3 installation equivalent to
[`composer require typo3/cms`](https://packagist.org/packages/typo3/cms) with
[ImageMagick](https://www.imagemagick.org/) and configured for
[Composer Mode](https://wiki.typo3.org/Composer#Composer_Mode).

Such a TYPO3 container can be linked to a
[MySQL or a PostgreSQL container](#using-mariadb-or-postgresql)
but can be run also independently owing to the built-in SQLite database.

You may use your favorite IDE on the host to work on TYPO3 in the container.
File access rights, ownerships, UIDs and GIDs are transparently and consistently
mapped between host and container.

Apache, PHP and Composer do not need to be installed on the host.

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
    -   [Composer](#composer)
    -   [Using your favorite IDE](#using-your-favorite-ide)
        -   [Preparation](#preparation)
        -   [Developing](#developing-1)
        -   [Changing the runtime environment](#changing-the-runtime-environment)
        -   [Debugging with XDebug](#debugging-with-xdebug)
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

If you prefer
[working rootless](https://de.slideshare.net/AkihiroSuda/rootless-containers)
with [Podman](https://podman.io/) then substitute `podman` for `docker` 
where applicable, or simply set `alias docker=podman`.

The resulting image is based on [Alpine Linux](https://alpinelinux.org/), Apache and
PHP&nbsp;7 and is quite compact (280&nbsp;MB).


## Running TYPO3

### TL;DR (quick & dirty)

For a TYPO3 instance in a standalone container, do this:
```bash
$ docker run \
    --detach \
    --name typo3 \
    --hostname dev.typo3.local \
    --volume typo3-vol:/var/www/localhost \
    --publish 127.0.0.1:8080:80 \
    localhost/typo3-dev
```

Next, browse to `http://localhost:8080`. This starts the TYPO3 installation wizard. 
When asked to select a database, choose `Manually configured SQLite connection` and
continue through the remaining dialogs to the TYPO3 login dialog.

[Volume](#volumes) `typo3-vol` persists the state of the TYPO3 installation
beyond container lifetime.

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
    --volume typo3-vol:/var/www/localhost \
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
    --volume typo3-vol:/var/www/localhost \
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

Volumes can be attached to the following container paths in order to persist
the TYPO3 installation state beyond container lifetime: 

-   `/var/www/localhost`: TYPO3 installation directory where
    `composer.json` is located. The TYPO3 SQLite database (if any) can 
    be found at `/var/www/localhost/var/sqlite`.
-   `/bitnami/mariadb`: contains the MariaDB database, otherwise not available.
-   `/bitnami/postgresql`: contains the PostgreSQL database, otherwise not available.

### Runtime configuration

##### `--hostname`

Determines both the container hostname and the Apache
`ServerName` and `ServerAdmin`. If `--hostname` is omitted
then the container gets a random hostname, and `ServerName`
defaults to `localhost`.

##### `--env` variables

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

`--env` variables can be altered even
[when the container is running](#changing-the-runtime-environment).

## Developing

### Composer

To manage your TYPO3 installation, run [Composer](https://wiki.typo3.org/Composer)
_only within the container_, e.g.
```bash
$ docker exec typo3 composer require bk2k/bootstrap-package
```

No working directory needs to be set since the container's `composer` command
always acts on the TYPO3 installation.

Note that neither Composer nor PHP have to be installed on the host.

### Using your favorite IDE

The TYPO3 installation is accessible outside of the 
container at the mount point of `typo3-vol`. However, UIDs and GIDs have been
mapped into user namespace and therefore are different from your own ones:
```bash
$ ls -lA $(docker volume inspect --format '{{.MountPoint}}' typo3-vol)

-rw-r--r--  1 100099 100100   1117 Mai  3 23:00 composer.json
-rw-r--r--  1 100099 100100 155056 Mai  3 23:01 composer.lock
drwxr-xr-x  6 100099 100100   4096 Mai  3 22:58 public
drwxrwsr-x  7 100099 100100   4096 Mai  3 23:02 var
drwxr-xr-x 15 100099 100100   4096 Mai  3 23:01 vendor
```

Fortunately, there is [bindfs](https://bindfs.org/) (available for Debian-like
and MacOS hosts): it will provide a bind-mounted view of these files and directories
with their UIDs and GIDs mapped to your UID and GID.

#### Preparation

First, you have to create a mountpoint for such a mapped view. In order to
keep IDE settings out of the TYPO3 installation, this should be a
_subdirectory_ of your envisaged TYPO3 development directory :
```bash
$ T3_MAPPED=~/typo3-dev/vol-mapped

$ mkdir -p $T3_MAPPED
```

Now use `bindfs` to mount the `typo3-vol` directory at `$T3_MAPPED` with your
UID and GID:
```bash
$ T3_MNT=$(docker volume inspect --format '{{.MountPoint}}' typo3-vol)
$ T3_UID=$(stat --format '%u' $T3_MNT/public)   # unmapped UID
$ T3_GID=$(stat --format '%g' $T3_MNT/public)   # unmapped GID

$ sudo bindfs \
    --map=$T3_UID/$(id -u):@$T3_GID/@$(id -g) \
    $T3_MNT \
    $T3_MAPPED

# UIDs and GIDs mapped to the current user's UID and GID
$ ls -nA $T3_MAPPED

-rw-r--r--  1 1000 1000   1117 Mai  3 23:00 composer.json
-rw-r--r--  1 1000 1000 155056 Mai  3 23:01 composer.lock
drwxr-xr-x  6 1000 1000   4096 Mai  3 22:58 public
drwxrwsr-x  7 1000 1000   4096 Mai  3 23:02 var
drwxr-xr-x 15 1000 1000   4096 Mai  3 23:01 vendor
```

#### Developing

Open the _parent directory_ of `$T3_MAPPED` with your favorite IDE, e.g.
```bash
$ code $T3_MAPPED/..
```
Any changes
you make in your IDE will be propagated to the running container automagically.

#### Changing the runtime environment

[`--env` variables](#--env-variables) can be altered while the container
is running, e.g. in order to switch `MODE` or to experiment with `php.ini` settings:
```bash
$ docker exec typo3 setenv MODE=xdebug php_post_max_size=1M
```
These modifications are lost whenever the container is stopped.

#### Debugging with XDebug

TODO

#### Cleaning up

To clean up afterwards:
```bash
$ sudo umount $T3_MAPPED
```

### Accessing the TYPO3 database

TODO

## Licenses

Scripts in this repository are licensed under the GPL&nbsp;3.0.
This document is licensed under the Creative Commons license CC&nbsp;BY-SA&nbsp;3.0.
For licenses regarding container images, please refer to 
[this discussion](https://opensource.stackexchange.com/questions/7013/license-for-docker-images#answer-7015).
