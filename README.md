# Developing for TYPO3 with Docker or Podman

This project provides a containerized TYPO3 installation equivalent to
[`composer require typo3/cms`](https://packagist.org/packages/typo3/cms) with
[ImageMagick](https://www.imagemagick.org/) installed and configured for
[Composer Mode](https://wiki.typo3.org/Composer#Composer_Mode).

The image is based on [Alpine Linux](https://alpinelinux.org/), Apache and
PHP&nbsp;7 and is quite compact (280&nbsp;MB).

The TYPO3 container can be linked to a database container such as
[MySQL or PostgreSQL](#using-mariadb-or-postgresql)
but also can be run independently due to the built-in SQLite database.

You can use your favorite IDE on the host to develop for TYPO3 in the container.
File access rights, ownerships, UIDs and GIDs are transparently and consistently
mapped between host and container. PHP and Composer do not need to be installed
on the host.


## Contents

-   [Running TYPO3](#running-typo3)
    -   [TL;DR (quick & dirty)](#tldr-quick--dirty)
    -   [Using MariaDB or PostgreSQL](#using-mariadb-or-postgresql)
        -   [Docker Compose](#docker-compose)
        -   [Podman](#podman)
        -   [Podman pod](#podman-pod)
    -   [Volumes](#volumes)
    -   [Ports](#ports)
    -   [Database credentials](#database-credentials)
    -   [TYPO3 runtime configuration](#typo3-runtime-configuration)
-   [Developing for TYPO3](#developing-for-typo3)
    -   [Composer](#composer)
    -   [Using your favorite IDE](#using-your-favorite-ide)
        -   [Background](#background)
        -   [Preparation](#preparation)
        -   [Developing](#developing-1)
        -   [Changing the runtime environment](#changing-the-runtime-environment)
        -   [Debugging with XDebug](#debugging-with-xdebug)
        -   [Cleaning up](#cleaning-up)
    -   [Accessing the TYPO3 database](#accessing-the-typo3-database)
-   [Licenses](#licenses)


## Running TYPO3

### TL;DR (quick & dirty)

To start a TYPO3 instance in a standalone container, do this:

```bash
$ docker run \
    --detach \
    --rm \
    --name typo3 \
    --hostname dev.typo3.local \
    --volume typo3-vol:/var/www/localhost \
    --publish 127.0.0.1:8080:80 \
    undecaf/typo3-dev
```

If you prefer
[working rootless](https://de.slideshare.net/AkihiroSuda/rootless-containers)
with [Podman](https://podman.io/) then substitute `podman` for `docker`,
or simply set `alias docker=podman`.

Next, browse to `http://localhost:8080`. This starts the TYPO3 installation wizard. 
When asked to select a database, choose `Manually configured SQLite connection` and
continue through the remaining dialogs to the TYPO3 login dialog.

[Volume](#volumes) `typo3-vol` persists the state of the TYPO3 installation
independently of container lifetime.


### Using MariaDB or PostgreSQL

The following examples show how to employ MariaDB
([`bitnami/mariadb`](https://hub.docker.com/r/bitnami/mariadb)) 
or PostgreSQL ([`bitnami/postgresql`](https://hub.docker.com/r/bitnami/postgresql))
as TYPO3 database.


#### Docker Compose

If [Docker Compose](https://docs.docker.com/compose/) is installed on your host then
[`docker-compose-typo3-mariadb.yml`](https://raw.githubusercontent.com/undecaf/typo3-dev/master/docker-compose-typo3-mariadb.yml)
will start TYPO3 with MariaDB:

```bash
$ docker-compose -f docker-compose-typo3-mariadb.yml up -d
```

For PostgreSQL, use
[`docker-compose-typo3-postgresql.yml`](https://raw.githubusercontent.com/undecaf/typo3-dev/master/docker-compose-typo3-postgresql.yml) instead.


#### Podman

The scripts
[`podman-typo3-mariadb.sh`](https://raw.githubusercontent.com/undecaf/typo3-dev/master/podman-typo3-mariadb.sh) and
[`podman-typo3-postgresql.sh`](https://raw.githubusercontent.com/undecaf/typo3-dev/master/podman-typo3-postgresql.sh)
start the TYPO3 and the database container separately but with a shared network
stack. `127.0.0.1` is shared _among_ the containers but is separate from `127.0.0.1`
at the host.


#### Podman pod

[`podman-pod-typo3-mariadb.sh`](https://raw.githubusercontent.com/undecaf/typo3-dev/master/podman-pod-typo3-mariadb.sh) and
[`podman-pod-typo3-postgresql.sh`](https://raw.githubusercontent.com/undecaf/typo3-dev/master/podman-pod-typo3-postgresql.sh)
create a
[pod](https://developers.redhat.com/blog/2019/01/15/podman-managing-containers-pods/)
named `typo3-pod` which contains the TYPO3 and the database containers.
This pod can be managed as a unit:

```bash
# Stops the pod
$ podman pod stop typo3-pod

# (Re-)Starts the pod
$ podman pod start typo3-pod
```


### Volumes

Named volumes persist the TYPO3 state beyond container lifetime.
Volume names and their mountpoints are:

-   `typo3-vol:/var/www/localhost`: TYPO3 installation directory where
    `composer.json` is located. The TYPO3 SQLite database (if used) can 
    be found at `/var/www/localhost/var/sqlite`.
-   `mariadb-vol:/bitnami/mariadb`: contains the MariaDB database if used.
-   `postgresql-vol:/bitnami/postgresql`: contains the PostgreSQL database if used.

Please note that [Docker Compose](#docker-compose) prepends volume names with
a project name.


### Ports

Container ports are mapped only to ports on host IP&nbsp;`127.0.0.1` so that
they are not reachable from the outside:
-   TYPO3: `8080`
-   MariaDB: `3306`
-   PostgreSQL: `5432`


### Database credentials

The database name, the database username and the password are all set to `t3`.
And yes, security could be improved here...


### TYPO3 runtime configuration

##### `--hostname` / `container_name`

Determines both the TYPO3 container hostname and the Apache
`ServerName` and `ServerAdmin`. If omitted
then the TYPO3 container gets a random hostname, and `ServerName`
defaults to `localhost`.

##### `--env` / `environment` settings

-   `TIMEZONE`: sets the TYPO3 container timezone (e.g. `Europe/Vienna`),
    default: UTC.

-   `MODE`:
    -   `prod` (default) selects production mode: TYPO3 in „Production Mode“,
        no Apache/PHP signature headers, PHP settings as per
        [`php.ini-production`](https://github.com/php/php-src/blob/master/php.ini-production)
    -   `dev` selects development mode, i.e. TYPO3 operating in „Development Mode“,
        verbose Apache/PHP signature headers, PHP settings as recommended by
        [`php.ini-development`](https://github.com/php/php-src/blob/master/php.ini-development)
    -   `xdebug` selects development mode as above and also enables 
        [XDebug](https://xdebug.org/)

-   `PHP_...`: environment variables prefixed with `PHP_` or `php_` become `php.ini`
    settings with the prefix removed, e.g. `--env php_post_max_size=5M` becomes 
    `post_max_size=5M`. These settings override prior settings and `MODE`.

`--hostname` and `--env` arguments can given to any of the `podman-*` scripts.

`--env` settings can be altered even
[while the container is running](#changing-the-runtime-environment).


## Developing for TYPO3

### Composer

To manage your TYPO3 installation, run [Composer](https://wiki.typo3.org/Composer)
_within the container_, e.g.

```bash
$ docker exec typo3 composer require bk2k/bootstrap-package
```

No working directory needs to be set since the container's `composer` command
always acts on the TYPO3 installation.

Note that neither Composer nor PHP have to be installed on the host.


### Using your favorite IDE

#### Background

The TYPO3 installation is accessible outside of the 
container at the mount point of `typo3-vol`. However, the container's UIDs and GIDs
are different from your own ones.

##### View container UIDs and GIDs using Docker

```bash
$ sudo ls -nA $(sudo docker volume inspect --format '{{.Mountpoint}}' typo3-vol)

-rw-r--r--  1 100 101   1117 Mai  3 23:00 composer.json
-rw-r--r--  1 100 101 155056 Mai  3 23:01 composer.lock
drwxr-xr-x  6 100 101   4096 Mai  3 22:58 public
drwxrwsr-x  7 100 101   4096 Mai  3 23:02 var
drwxr-xr-x 15 100 101   4096 Mai  3 23:01 vendor
```

##### View container UIDs and GIDs using Podman (rootless)

```bash
$ ls -nA $(podman volume inspect --format '{{.MountPoint}}' typo3-vol)

-rw-r--r--  1 100099 100100   1117 Mai  3 23:00 composer.json
-rw-r--r--  1 100099 100100 155056 Mai  3 23:01 composer.lock
drwxr-xr-x  6 100099 100100   4096 Mai  3 22:58 public
drwxrwsr-x  7 100099 100100   4096 Mai  3 23:02 var
drwxr-xr-x 15 100099 100100   4096 Mai  3 23:01 vendor
```


#### Preparation

[bindfs](https://bindfs.org/) (available for Debian-like and MacOS hosts)
is a [FUSE](https://github.com/libfuse/libfuse) filesystem that provides
a bind-mounted view of these files and directories with their UIDs and GIDs
mapped to your UID and GID.

First install [bindfs](https://bindfs.org/) from the repositories of your
distribution.

Then create a mountpoint for a mapped view. In order to
keep IDE settings out of the TYPO3 installation, this should be a
_subdirectory_ of your envisaged TYPO3 development directory:

```bash
$ T3_MAPPED=~/typo3-dev/vol-mapped

$ mkdir -p $T3_MAPPED
```

Now use bindfs to mount the `typo3-vol` directory at `$T3_MAPPED` with your
UID and GID:

```bash
# Using Docker:
$ T3_MNT=$(sudo docker volume inspect --format '{{.Mountpoint}}' typo3-vol)
$ T3_UID=$(sudo stat --format '%u' $T3_MNT/public)   # unmapped UID
$ T3_GID=$(sudo stat --format '%g' $T3_MNT/public)   # unmapped GID

# Using Podman (rootless):
$ T3_MNT=$(podman volume inspect --format '{{.MountPoint}}' typo3-vol)
$ T3_UID=$(stat --format '%u' $T3_MNT/public)        # unmapped UID
$ T3_GID=$(stat --format '%g' $T3_MNT/public)        # unmapped GID

# Bind-mount typo3-vol with mapped UIDs/GIDs
$ sudo bindfs \
    --map=$T3_UID/$(id -u):@$T3_GID/@$(id -g) \
    $T3_MNT \
    $T3_MAPPED

# UIDs/GIDs now mapped to the current user's UID/GID
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

[`--env` settings](#--env--environment-settings) can be altered while the container
is running, e.g. in order to switch `MODE` or to experiment with different
`php.ini` settings:

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
