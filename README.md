# Developing for TYPO3 with Docker or Podman

[![Build Status](https://travis-ci.com/undecaf/typo3-dev.svg?branch=master)](https://travis-ci.com/undecaf/typo3-dev)

This project provides a containerized TYPO3 installation equivalent to
[`composer require typo3/cms`](https://packagist.org/packages/typo3/cms) with
[ImageMagick](https://www.imagemagick.org/) installed and configured for
[Composer Mode](https://wiki.typo3.org/Composer#Composer_Mode).
The image is based on [Alpine Linux](https://alpinelinux.org/), Apache and PHP&nbsp;7 and is compact.

The TYPO3 container can be linked to a database container such as
[MySQL or PostgreSQL](#using-mariadb-or-postgresql)
but also can be run independently due to the built-in SQLite database.

You can use your favorite IDE on the host to
[develop for TYPO3](#developing-for-typo3) in the container,
including [remote debugging with XDebug](#debugging-with-xdebug).
Your extension development directories can be
[excluded from changes made by Composer](#typo3-runtime-configuration).
PHP and Composer do not need to be installed on the host.

File access rights, ownerships, UIDs and GIDs are transparently and consistently
[mapped between host and container](#preparation).

## What you get

![Parts of this project in a block diagram: containers for TYPO3 and database, browser and IDE](https://undecaf.github.io/typo3-dev/img/overview.png)

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
        -   [Developing](#developing)
        -   [Changing the runtime environment](#changing-the-runtime-environment)
        -   [Debugging with XDebug](#debugging-with-xdebug)
        -   [Cleaning up](#cleaning-up)
    -   [Accessing the TYPO3 database](#accessing-the-typo3-database)
-   [Licenses](#licenses)


## Running TYPO3

### TL;DR (quick & dirty)

To start a TYPO3 instance in a standalone container, do this
(or run
[`docker-run.sh`](https://raw.githubusercontent.com/undecaf/typo3-dev/master/shell/docker-run.sh)):

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
or simply set `alias docker=podman`, or use
[`podman-run.sh`](https://raw.githubusercontent.com/undecaf/typo3-dev/master/shell/podman-run.sh).

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
[`typo3-mariadb.yml`](https://raw.githubusercontent.com/undecaf/typo3-dev/master/docker-compose/typo3-mariadb.yml)
will start TYPO3 with MariaDB:

```bash
$ docker-compose -f docker-compose/typo3-mariadb.yml up -d
```

For PostgreSQL, use
[`typo3-postgresql.yml`](https://raw.githubusercontent.com/undecaf/typo3-dev/master/docker-compose/typo3-postgresql.yml) instead.


#### Podman

The scripts
[`podman-typo3-mariadb.sh`](https://raw.githubusercontent.com/undecaf/typo3-dev/master/shell/podman-typo3-mariadb.sh) and
[`podman-typo3-postgresql.sh`](https://raw.githubusercontent.com/undecaf/typo3-dev/master/shell/podman-typo3-postgresql.sh)
start the TYPO3 and the database container separately but with a shared network
stack. `127.0.0.1` is shared _among_ the containers but is separate from `127.0.0.1`
at the host.


#### Podman pod

[`podman-pod-typo3-mariadb.sh`](https://raw.githubusercontent.com/undecaf/typo3-dev/master/shell/podman-pod-typo3-mariadb.sh) and
[`podman-pod-typo3-postgresql.sh`](https://raw.githubusercontent.com/undecaf/typo3-dev/master/shell/podman-pod-typo3-postgresql.sh)
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
Volume names and their container mountpoints are:

-   `typo3-vol:/var/www/localhost`: TYPO3 installation directory where
    `composer.json` is located. The TYPO3 SQLite database (if used) can 
    be found at `/var/www/localhost/var/sqlite`,
    Apache and XDebug logs at `/var/www/logs`.
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

#### `--hostname` / `container_name`

Determines both the TYPO3 container hostname and the Apache
`ServerName` and `ServerAdmin`. If omitted
then the TYPO3 container gets a random hostname, and `ServerName`
defaults to `localhost`.

#### `--env` / `environment` settings

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

-   `COMPOSER_EXCLUDE`: a colon-separated list of directory paths relative to
    `/var/www/localhost` which are to be excluded from the effects of [Composer operations](#composer).  
    This is intended e.g. to protect the current version of
    an extension you are developing from being „updated“ to an older version stored in a repository.  
    The directories need to exist only when Composer is invoked.

`--hostname` and `--env` arguments can be given to any of the `podman-*` scripts.

`--env` settings can be altered even
[while the container is running](#changing-the-runtime-environment).


## Developing for TYPO3

### Composer

To manage your TYPO3 installation, run [Composer](https://wiki.typo3.org/Composer)
_within the container_, e.g.

```bash
$ docker exec typo3 composer require bk2k/bootstrap-package
```

As a convenience, the scripts 
[docker-composer.sh](https://raw.githubusercontent.com/undecaf/typo3-dev/master/shell/docker-composer.sh) and
[podman-composer.sh](https://raw.githubusercontent.com/undecaf/typo3-dev/master/shell/podman-composer.sh)
can be used similar to the `composer` command:

```bash
$ docker-composer.sh require bk2k/bootstrap-package
```

In the container `composer` always acts on the
TYPO3 installation.
Neither Composer nor PHP have to be installed on the host.


### Using your favorite IDE

#### Background

The TYPO3 installation is accessible outside of the 
container at the mount point of `typo3-vol`. However, the container's UIDs and GIDs
are different from your own ones:

```bash
$ sudo ls -nA $(sudo docker volume inspect --format '{{.Mountpoint}}' typo3-vol)

-rw-r--r--  1 100 101   1117 Mai  3 23:00 composer.json
-rw-r--r--  1 100 101 155056 Mai  3 23:01 composer.lock
drwxr-xr-x  6 100 101   4096 Mai  3 22:58 public
drwxrwsr-x  7 100 101   4096 Mai  3 23:02 var
drwxr-xr-x 15 100 101   4096 Mai  3 23:01 vendor
```

Showing rootless Podman container UIDs and GIDs:

```bash
$ ls -nA $(podman volume inspect --format '{{.MountPoint}}' typo3-vol)

-rw-r--r--  1 100099 100100   1117 Mai  3 23:00 composer.json
-rw-r--r--  1 100099 100100 155056 Mai  3 23:01 composer.lock
drwxr-xr-x  6 100099 100100   4096 Mai  3 22:58 public
drwxrwsr-x  7 100099 100100   4096 Mai  3 23:02 var
drwxr-xr-x 15 100099 100100   4096 Mai  3 23:01 vendor
```


#### Preparation

[bindfs](https://bindfs.org/) (available only for Debian-like and MacOS hosts)
is a [FUSE](https://github.com/libfuse/libfuse) filesystem that
resolves this situation. It can provide a bind-mounted view of
the files and directories in a volume with their UIDs and GIDs
mapped to your own UID and GID.

First install [bindfs](https://bindfs.org/) from the repositories of your
distribution.

Then use either
[`mount-docker-vol.sh`](https://raw.githubusercontent.com/undecaf/typo3-dev/master/shell/mount-docker-vol.sh) or
[`mount-podman-vol.sh`](https://raw.githubusercontent.com/undecaf/typo3-dev/master/shell/mount-podman-vol.sh)
to mount a view of `typo3-vol` at a _subdirectory_ of your
TYPO3 development workspace (in order to keep IDE settings out
of the TYPO3 installation), e.g.:

```bash
$ mount-docker-vol.sh typo3-vol ~/typo3-dev/typo3-vol-mapped
```

Now your appear to be the owner of the files in `typo3-vol-mapped`:

```bash
$ ls -nA ~/typo3-dev/typo3-vol-mapped

-rw-r--r--  1 1000 1000   1117 Mai  3 23:00 composer.json
-rw-r--r--  1 1000 1000 155056 Mai  3 23:01 composer.lock
drwxr-xr-x  6 1000 1000   4096 Mai  3 22:58 public
drwxrwsr-x  7 1000 1000   4096 Mai  3 23:02 var
drwxr-xr-x 15 1000 1000   4096 Mai  3 23:01 vendor
```

#### Developing

Open the TYPO3 development workspace with your favorite IDE, e.g.

```bash
$ code ~/typo3-dev
```

Any changes you make in your IDE will be propagated to the running container
automagically with your UID/GID mapped back to container UIDs/GIDs.


#### Changing the runtime environment

[`--env` settings](#--env--environment-settings) can be altered while the container
is running, e.g. in order to switch `MODE` or to experiment with different
`php.ini` settings:

```bash
$ docker exec typo3 setenv MODE=xdebug php_post_max_size=1M
```

[docker-setenv.sh](https://raw.githubusercontent.com/undecaf/typo3-dev/master/shell/docker-setenv.sh) and
[podman-setenv.sh](https://raw.githubusercontent.com/undecaf/typo3-dev/master/shell/podman-setenv.sh)
can save a little bit of typing:

```bash
$ docker-setenv MODE=xdebug php_post_max_size=1M
```

These modifications are lost whenever the container is stopped.


#### Debugging with XDebug

##### Set up your IDE for XDebug

-   PhpStorm et al.: [Debugging within a PHP Docker Container using IDEA/PhpStorm and Xdebug: Configure IntelliJ IDEA Ultimate or PhpStorm](https://phauer.com/2017/debug-php-docker-container-idea-phpstorm/#configure-intellij-idea-ultimate-or-phpstorm)
-   VSCode: install 
    [PHP Debug](https://github.com/felixfbecker/vscode-php-debug),
    add the following configuration to your `launch.json` file
    and start debugging with this configuration. If necessary, replace `typo3-vol-mapped` with the actual mount directory of `typo3-vol`:
    ```json
    {
        "name": "Listen for XDebug from container",
        "type": "php",
        "request": "launch",
        "port": 9000,
        "pathMappings": {
            "/var/www/localhost": "${workspaceRoot}/typo3-vol-mapped"
        }
    }
    ```


##### Install browser debugging plugins

Although not strictly required, debugging plugins make starting
a XDebug session more convenient.
[Browser Debugging Extensions](https://www.jetbrains.com/help/phpstorm/browser-debugging-extensions.html#Browser_Debugging_Extensions.xml)
lists recommended plugins for various browsers.


##### Activate XDebug in the container

Podman containers must be told the host IP in order for XDebug
to connect back to your IDE. If you did not start TYPO3 with one
of the scripts, your `podman run` command  must include this argument:

```bash
--env HOST_IP=$(hostname -I | awk '{print $1}')
```

Unless the container was started with `MODE=xdebug`, this mode
needs to be activated now:

```bash
$ docker-setenv.sh MODE=xdebug
```

Now everything is ready to start a XDebug session.


#### Cleaning up

To clean up afterwards:

```bash
$ sudo umount ~/typo3-dev/typo3-vol-mapped
```


### Accessing the TYPO3 database

#### SQLite

`typo3-vol` needs to be mounted as [described above](#preparation).
Point your database client at the file `var/sqlite/cms-*.sqlite`
in the mounted volume.
This is the TYPO3 SQLite database. The actual filename contains
a random part.


#### MariaDB and PostgreSQL

`typo3-vol` does not need to be mounted. MariaDB is published at
`127.0.0.1:3306` and PostgreSQL at `127.0.0.1:5432`.

The database name, user name and password are all set to `t3`.
Yes, I know.



## Licenses

Scripts in this repository are licensed under the GPL&nbsp;3.0.
This document is licensed under the Creative Commons license CC&nbsp;BY-SA&nbsp;3.0.
For licenses regarding container images, please refer to 
[this discussion](https://opensource.stackexchange.com/questions/7013/license-for-docker-images#answer-7015).
