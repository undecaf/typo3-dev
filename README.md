# Developing for TYPO3 with Docker or Podman

[![Build Status](https://travis-ci.com/undecaf/typo3-dev.svg?branch=master)](https://travis-ci.com/undecaf/typo3-dev)

This project provides a containerized TYPO3 installation equivalent to
[`composer require typo3/cms`](https://packagist.org/packages/typo3/cms) with
[ImageMagick](https://www.imagemagick.org/) installed and configured for
[Composer Mode](https://wiki.typo3.org/Composer#Composer_Mode).
The image is based on [Alpine Linux](https://alpinelinux.org/), Apache and PHP&nbsp;7 and is only 280&nbsp;MB in size.

The TYPO3 container can be combined with a database container such as
[MySQL or PostgreSQL](#using-mariadb-or-postgresql)
but also can be run independently due to the built-in SQLite database.
Setting up and managing these scenarios is simplified by a shell script.

You can use your favorite IDE on the host to
[develop for TYPO3](#developing-for-typo3) in the container,
including [remote debugging with XDebug](#debugging-with-xdebug).
Your extension development directories can be
[excluded from changes made by Composer](#other-settings).
PHP and Composer do not need to be installed on the host.

File access rights, ownerships, UIDs and GIDs are transparently and consistently
[mapped between host and container](#making-mapped-files-editable).

## What you get

![Parts of this project in a block diagram: containers for TYPO3 and database, browser and IDE](https://undecaf.github.io/typo3-dev/img/overview.png)

## Contents

-   [Running TYPO3](#running-typo3)
    -   [Quick start](#quick-start)
    -   [Shell scripts](#shell-scripts)
    -   [Using MariaDB or PostgreSQL](#using-mariadb-or-postgresql)
        -   [Docker Compose](#docker-compose)
        -   [Podman](#podman)
        -   [Podman pod](#podman-pod)
    -   [Volumes](#volumes)
    -   [Ports](#ports)
    -   [Other settings](#other-settings)
-   [Developing for TYPO3](#developing-for-typo3)
    -   [Composer](#composer)
    -   [Using your favorite IDE](#using-your-favorite-ide)
        -   [Background](#background)
        -   [Making mapped files editable](#making-mapped-files-editable)
        -   [Working with an IDE](#working-with-an-ide)
        -   [Changing the runtime environment](#changing-the-runtime-environment)
        -   [Debugging with XDebug](#debugging-with-xdebug)
        -   [Cleaning up](#cleaning-up)
    -   [Accessing the TYPO3 database](#accessing-the-typo3-database)
-   [Credits](#credits)
-   [Licenses](#licenses)


## Running TYPO3

### Quick start

To start a TYPO3 instance in a standalone container, enter this command
or run the [shell script](#shell-scripts) `t3run`:

```bash
$ docker run \
    --volume typo3-root:/var/www/localhost \
    --publish 127.0.0.1:8080:80 \
    undecaf/typo3-dev
```

If you prefer
[working rootless](https://de.slideshare.net/AkihiroSuda/rootless-containers)
with [Podman](https://podman.io/) then substitute `podman` for `docker`.
`t3run` uses Podman automatically if it is installed.

Next, browse to `http://localhost:8080`. This starts the TYPO3 installation wizard. 
When asked to select a database, choose `Manually configured SQLite connection` and
continue through the remaining dialogs to the TYPO3 login dialog.

[Volume](#volumes) `typo3-root` persists the state of the TYPO3 installation
independently of container lifetime.


### Shell scripts

TODO


### Using MariaDB or PostgreSQL

The following examples show how to employ MariaDB
([`bitnami/mariadb`](https://hub.docker.com/r/bitnami/mariadb)) 
or PostgreSQL ([`bitnami/postgresql`](https://hub.docker.com/r/bitnami/postgresql))
as the TYPO3 database.


#### Docker Compose

If [Docker Compose](https://docs.docker.com/compose/) is installed on your host then
[`typo3-mariadb.yml`](https://raw.githubusercontent.com/undecaf/typo3-dev/master/docker-compose/typo3-mariadb.yml)
will start TYPO3 with MariaDB:

```bash
$ docker-compose -f docker-compose/typo3-mariadb.yml up -d
```

For PostgreSQL, use
[`typo3-postgresql.yml`](https://raw.githubusercontent.com/undecaf/typo3-dev/master/docker-compose/typo3-postgresql.yml) instead.

Please note that [Docker Compose](#docker-compose) prepends [volume names](#volumes)
with a project name.

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
[`t3run`](https://raw.githubusercontent.com/undecaf/typo3-dev/master/shell/t3run)
establishes the following mappings by default:

-   `typo3-root:/var/www/localhost`: TYPO3 installation directory where
    `composer.json` is located.  
    The TYPO3 SQLite database (if used) is located at
    `/var/www/localhost/var/sqlite`,
    Apache and XDebug logs at `/var/www/logs`.
-   `mariadb-data:/bitnami/mariadb`: contains the MariaDB database if used.
-   `postgresql-data:/bitnami/postgresql`: contains the PostgreSQL database if used.

Different default volume names or (absolute) paths can be defined in environment variables
`T3_ROOT`, `T3_MARIA_DATA` and `T3_PG_DATA`, respectively.
Defaults can be overriden per invocation by options
[`t3run [-v|-w]`](https://raw.githubusercontent.com/undecaf/typo3-dev/master/shell/t3run).


### Ports

By default,
[`t3run`](https://raw.githubusercontent.com/undecaf/typo3-dev/master/shell/t3run)
maps container ports only to ports on host IP&nbsp;`127.0.0.1`
so that they are not accessible from the outside:

-   TYPO3: `127.0.0.1:8080` ← `80`
-   MariaDB: `127.0.0.1:3306` ← `3306`
-   PostgreSQL: `127.0.0.1:5432` ← `5432`

Use the Docker
[`--publish`](https://docs.docker.com/config/containers/container-networking/#published-ports) 
option for different port mappings.


### Other settings

These settings can be used with
[`t3run`](https://raw.githubusercontent.com/undecaf/typo3-dev/master/shell/t3run),
with `docker run` and `podman run` commands and in Docker Compose files.

Some defaults are set only by `t3run`; if starting TYPO3 in a different way then
these parameters must be set explicitly .


#### `--hostname` / `container_name`

Determines both the TYPO3 container hostname and the Apache
`ServerName` and `ServerAdmin`. `t3run` default: `typo3.<host-hostname>`.  

#### `--env` / `environment` settings

-   `TIMEZONE`: sets the TYPO3 container timezone (e.g. `Europe/Vienna`).
    If not specified then the container tries to use the timezone of your
    current location, or else assumes UTC.

-   `MARIADB_DATABASE`, `MARIADB_USER`, `MARIADB_PASSWORD` and
    `MARIADB_ROOT_PASSWORD`: MariaDB credentials.
    `t3run` defaults: `t3`, and `toor`for `MARIADB_ROOT_PASSWORD`.

-   `POSTGRESQL_DATABASE`, `POSTGRESQL_USERNAME`, `POSTGRESQL_PASSWORD`:
    PostgreSQL credentials. `t3run` defaults: `t3`.

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
    an extension you are developing from being overwritten by an older version stored in a repository.  
    These directories must exist by the time Composer is invoked.

-   `HOST_IP`: host IP address, required only for Podman containers to enable
    [XDebug to connect back to your IDE](#activate-xdebug-in-the-container);
    set by `t3run`. If starting TYPO3 with `podman run` then include this option:

    ```bash
    --env HOST_IP=$(hostname -I | awk '{print $1}')
    ```
`MODE`, `PHP_...` and `COMPOSER_EXCLUDE` can be altered even
[while the container is running](#changing-the-runtime-environment).


## Developing for TYPO3

### Composer

Script
[`t3composer`](https://raw.githubusercontent.com/undecaf/typo3-dev/master/shell/t3composer)
lets you manage your TYPO3 installation. It is equivalent to running
[Composer](https://wiki.typo3.org/Composer) _from within the container_, e.g.

```bash
$ t3composer require bk2k/bootstrap-package
```

[`t3composer`](https://raw.githubusercontent.com/undecaf/typo3-dev/master/shell/t3composer)
and the `composer` script found in the container always act on the TYPO3
installation directory.
Neither Composer nor PHP have to be installed on the host.

[XDebug should be deactivated](#activate-xdebug-in-the-container) before 
running Composer because it might slow down Composer significantly.


### Using your favorite IDE

#### Background

The TYPO3 installation is accessible outside of the 
container at the mount point of `typo3-root` which can be obtained by `inspect`ing
the container. The files, however, are owned by a system account and cannot be edited
by you:

```bash
$ sudo ls -nA $(sudo docker volume inspect --format '{{.Mountpoint}}' typo3-root)

-rw-r--r--  1 100 101   1117 Mai  3 23:00 composer.json
-rw-r--r--  1 100 101 155056 Mai  3 23:01 composer.lock
drwxr-xr-x  6 100 101   4096 Mai  3 22:58 public
drwxrwsr-x  7 100 101   4096 Mai  3 23:02 var
drwxr-xr-x 15 100 101   4096 Mai  3 23:01 vendor
```

With Podman, files are owned by one of your sub-UIDs which leads to the same problem.


#### Making mapped files editable

[bindfs](https://bindfs.org/) (available only for Debian-like and MacOS hosts)
is a [FUSE](https://github.com/libfuse/libfuse) filesystem that
resolves this situation (osxfuse needed). It can provide a bind-mounted _view_ of
the files and directories in a volume with their UIDs and GIDs
mapped to your own UID and GID. This does not affect UIDs and GIDs seen by the
container.

First install [bindfs](https://bindfs.org/) from the repositories of your
distribution.

<a id="t3mount"></a>
Then use 
[`t3mount`](https://raw.githubusercontent.com/undecaf/typo3-dev/master/shell/t3mount)
to mount a view of `typo3-root` at a _subdirectory_ of your
TYPO3 development workspace (in order to keep IDE settings out
of the TYPO3 installation), e.g. at `typo3-root-mapped`:

```bash
$ t3mount typo3-root ~/typo3-dev/typo3-root-mapped
```

Now you _appear_ to be the owner of the files and directories in `typo3-root-mapped`,
and they can be edited by you:

```bash
$ ls -nA ~/typo3-dev/typo3-root-mapped

-rw-r--r--  1 1000 1000   1117 Mai  3 23:00 composer.json
-rw-r--r--  1 1000 1000 155056 Mai  3 23:01 composer.lock
drwxr-xr-x  6 1000 1000   4096 Mai  3 22:58 public
drwxrwsr-x  7 1000 1000   4096 Mai  3 23:02 var
drwxr-xr-x 15 1000 1000   4096 Mai  3 23:01 vendor
```

#### Working with an IDE

Open the TYPO3 development workspace with your favorite IDE, e.g.

```bash
$ code ~/typo3-dev
```

Any changes you make in your IDE will be propagated to the running container
automagically with your UID/GID mapped back to container UIDs/GIDs.


#### Changing the runtime environment

Script 
[`t3env`](https://raw.githubusercontent.com/undecaf/typo3-dev/master/shell/t3env)
can modify certain [`--env` settings](#--env--environment-settings) while the
container is running, e.g. in order to switch `MODE` or to experiment with
different `php.ini` settings:

```bash
$ t3env MODE=xdebug php_post_max_size=1M
```

These modifications are lost whenever the container is stopped.


#### Debugging with XDebug

##### Set up your IDE for XDebug

-   PhpStorm et al.: [Debugging within a PHP Docker Container using IDEA/PhpStorm and Xdebug: Configure IntelliJ IDEA Ultimate or PhpStorm](https://phauer.com/2017/debug-php-docker-container-idea-phpstorm/#configure-intellij-idea-ultimate-or-phpstorm)
-   VSCode: install 
    [PHP Debug](https://github.com/felixfbecker/vscode-php-debug),
    add the following configuration to your `launch.json` file
    and start debugging with this configuration. If necessary, replace `typo3-root-mapped` with the actual [mount directory](#t3mount) of
    `typo3-root`:

    ```json
    {
        "name": "Listen for XDebug from container",
        "type": "php",
        "request": "launch",
        "port": 9000,
        "pathMappings": {
            "/var/www/localhost": "${workspaceRoot}/typo3-root-mapped"
        }
    }
    ```


##### Install browser debugging plugins

Although not strictly required, debugging plugins make starting
a XDebug session more convenient.
[Browser Debugging Extensions](https://www.jetbrains.com/help/phpstorm/browser-debugging-extensions.html#Browser_Debugging_Extensions.xml)
lists recommended plugins for various browsers.


##### Activate XDebug in the container

Unless the container was started with `MODE=xdebug`, this mode
needs to be activated now:

```bash
$ t3env MODE=xdebug
```

Now everything is ready to start a XDebug session.


#### Cleaning up

To clean up afterwards:

```bash
$ sudo umount ~/typo3-dev/typo3-root-mapped
```


### Accessing the TYPO3 database

#### SQLite

`typo3-root` needs to be mounted as [described above](#making-mapped-files-editable).
Point your database client at the file `var/sqlite/cms-*.sqlite`
in the mounted volume.
This is the TYPO3 SQLite database. The actual filename contains a random part.


#### MariaDB and PostgreSQL

`typo3-root` does not need to be mounted. By default, MariaDB [is published](#ports)
at `127.0.0.1:3306` and PostgreSQL at `127.0.0.1:5432`.

The database credentials are part of the 
[environment settings](#--env--environment-settings).


## Credits

TODO


## Licenses

Scripts in this repository are licensed under the GPL&nbsp;3.0.
This document is licensed under the Creative Commons license CC&nbsp;BY-SA&nbsp;3.0.
For licenses regarding container images, please refer to 
[this discussion](https://opensource.stackexchange.com/questions/7013/license-for-docker-images#answer-7015).
