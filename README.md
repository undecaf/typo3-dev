## :warning: This repository is no longer being maintained and has been archived.

# Containerized TYPO3 – from quick start to extension development 

[![Build Status](https://travis-ci.com/undecaf/typo3-dev.svg?branch=master)](https://travis-ci.com/undecaf/typo3-dev)
[![Latest release](https://img.shields.io/github/release/undecaf/typo3-dev.svg)](https://github.com/undecaf/typo3-dev)
![Image Size](https://img.shields.io/microbadger/image-size/undecaf/typo3-dev/latest.svg)

This project provides a containerized TYPO3 installation equivalent to
[`composer require typo3/cms`](https://packagist.org/packages/typo3/cms) with
[ImageMagick](https://www.imagemagick.org/) installed and configured for
[Composer Mode](https://getcomposer.org/#Composer_Mode).
The image is based on [Alpine Linux&nbsp;3.10](https://alpinelinux.org/),
Apache&nbsp;2.4 and PHP&nbsp;7.3,
uses less than 300&nbsp;MB disk space and can run in
[Docker](https://www.docker.com/) and [Podman](https://podman.io/).

The TYPO3 container can be combined with a database container such as
[MySQL or PostgreSQL](#using-mariadb-or-postgresql)
but also can be run independently due to the built-in SQLite database.
Setting up and managing such scenarios is simplified by a shell script for Linux and macOS.

You can use your favorite IDE on the host to
[develop for TYPO3](#developing-for-typo3) in the container,
including [remote debugging with XDebug](#debugging-with-xdebug).
Your extension development directories can be
[excluded from changes made by Composer](#preventing-composer-from-overwriting-your-changes).
PHP and Composer do not need to be installed on the host.

File access rights, ownerships, UIDs and GIDs are transparently and consistently
[mapped between host and container](#using-an-ide).

## What you get

![Parts of this project in a block diagram: containers for TYPO3 and database, browser and IDE](https://undecaf.github.io/typo3-dev/img/overview.png)

## Contents

-   [Running TYPO3](#running-typo3)
    -   [Quick start](#quick-start)
    -   [`t3` shell script](#t3-shell-script)
    -   [Quick start with `t3`](#quick-start-with-t3)
    -   [MariaDB and PostgreSQL](#mariadb-and-postgresql)
-   [Developing for TYPO3](#developing-for-typo3)
    -   [Using an IDE](#using-an-ide)
    -   [Setting the container environment](#setting-the-container-environment)
    -   [Composer](#composer)
    -   [Debugging with XDebug](#debugging-with-xdebug)
    -   [Accessing the TYPO3 database](#accessing-the-typo3-database)
    -   [Managing multiple TYPO3 instances](#managing-multiple-typo3-instances)
-   [`t3` shell script reference](#t3-shell-script-reference)
    -   [Getting help](#getting-help)
    -   [`t3 run`](#t3-run)
    -   [`t3 stop`](#t3-stop)
    -   [`t3 env`](#t3-env)
    -   [`t3 composer`](#t3-composer)
    -   [`t3 mount`](#t3-mount)
    -   [`t3 unmount`](#t3-unmount)
    -   [Options](#options)
    -   [Host environment variables](#host-environment-variables)
    -   [Container environment variables](#container-environment-variables)
-   [Credits](#credits)
-   [Licenses](#licenses)


## Running TYPO3

### Quick start

To start a TYPO3 instance in a standalone container, enter this command:

```bash
$ docker run \
    --volume typo3-root:/var/www/localhost \
    --publish 127.0.0.1:8080:80 \
    undecaf/typo3-dev
```

If you prefer
[working rootless](https://de.slideshare.net/AkihiroSuda/rootless-containers)
with [Podman](https://podman.io/) then substitute `podman` for `docker`.

Next, browse to `http://localhost:8080`. This starts the TYPO3 installation wizard. 
When asked to select a database, choose `Manually configured SQLite connection` and
continue through the remaining dialogs to the TYPO3 login dialog.

Volume `typo3-root` persists the state of the TYPO3 instance
independently of container lifetime.


#### Online documentation

In order to view the version of this README file that matches the version of
the running TYPO3 instance, browse to `http://localhost:8080/readme.html`.


### `t3` shell script

More complex setups (such as using an external database) require complex Docker
or Podman command lines.

In order to simplify usage, the
[`t3` shell script](https://raw.githubusercontent.com/undecaf/typo3-dev/master/t3)
has been provided for Linux and macOS.
This script is
[avaliable for download here](https://raw.githubusercontent.com/undecaf/typo3-dev/master/t3).
 It lets you:
-   configure and run a TYPO3 container plus an optional database container;
-   stop these containers and optionally remove them;
-   map the TYPO3 root in the container to a working directory;
-   modify the TYPO3 environment even while the container is running;
-   run Composer within the TYPO3 container.

See the [`t3` reference](#t3-shell-script-reference) for a complete description.


### Quick start with `t3`

To run a TYPO3 standalone container [as shown above](#quick-start) with `t3`,
simply type:

```bash
$ t3 run --
```

`t3` chooses between [Docker](https://www.docker.com/) and 
[Podman](https://podman.io/) engines
automatically, depending on which one is installed. If both are, Podman will be preferred.

To stop and remove the container, enter

```bash
$ t3 stop --rm
```

State is preserved in volume `typo3-root` so that a subsequent `t3 run --`
command will resume from where you left off.


### MariaDB and PostgreSQL

MariaDB or PostgreSQL is optional for TYPO3&nbsp;v9.5+ but is required for TYPO3&nbsp;v8.7.

The following example starts a TYPO3 and a MariaDB container
([`bitnami/mariadb`](https://hub.docker.com/r/bitnami/mariadb)) and connects them,
preserves state in volumes `typo3-root` and `typo3-data` and exposes TYPO3 and 
MariaDB on ports `127.0.0.1:8080` and `127.0.0.1:3306`, respectively:

```bash
$ t3 run -d maria
```

For a PostgreSQL container
([`bitnami/postgresql`](https://hub.docker.com/r/bitnami/postgresql))
exposed on `127.0.0.1:5432`, replace `-d maria` with `-d postgres`.

Enter

```bash
$ t3 stop --
```

to stop _both_ containers. If you wish to have the stopped containers removed, too,
append `--rm` to `t3 run` or `t3 stop`.


#### Database credentials

Database credentials can be defined by [host environment variables](#host-environment-variables)
`T3_DB_NAME`, `T3_DB_USER` and `T3_DB_PW`. If not set then the database name, user and password
all default to `t3`.


## Developing for TYPO3

The following sections describes how this project can aid in customizing or 
developing TYPO3 extensions or otherwise altering the source code of your TYPO3
installation.

### Using an IDE

In order to work on your TYPO3 installation in an IDE, the TYPO3 root directory needs to be
exposed to a working directory where the current user has sufficient (read and write)
permissions. At the container volume mount point, this is usually not the case.

`t3` uses the [bindfs](https://bindfs.org/) utility  (available for Debian-like and
macOS hosts) to solve this problem. See below for what is happening [behind the scenes](#behind-the-scenes).

First, [bindfs](https://bindfs.org/) needs to be installed from the repositories
of your system. For macOS, [osxfuse](https://osxfuse.github.io/) is required beforehand.

When starting TYPO3, specify the path of the desired working directory
(e.g. `~/ide-workspace/typo3-root`) as the `-v` option to `t3 run`,
i.e. in the simplest case

```bash
$ t3 run -v ~/ide-workspace/typo3-root
```

This will
-   start the container(s),
-   create a TYPO3 volume having the working directory basename
    (`typo3-root`) as its name,
-   make the TYPO3 volume content appear in the working directory
    (`~/ide-workspace/typo3-root`) as if it were owned by the current user.

Thus, the TYPO3 instance can now be edited in the IDE. File changes,
creates and deletes will be passed in both directions between working directory
and container with the current user's UID/GID mapped to container UIDs/GIDs.

Stopping the TYPO3 container will unmount the working directory automatically.

__Podman users please note:__ working directories require at least Podman&nbsp;v1.4.3.


#### Editing a stopped TYPO3 instance

Whenever there is a persistent TYPO3 volume, you can edit that TYPO3 instance
even if the container is not running or does not even exist. Just mount your 
working directory on top of the volume:

```bash
$ t3 mount -m ~/ide-workspace/typo3-root
```

As with [`t3 run -v`](#using-an-ide), the name of the volume is the working
directory basename.

When you are finished, unmount your working directory again:

```bash
$ t3 unmount -u ~/ide-workspace/typo3-root
```

#### Behind the scenes

The TYPO3 root directory is accessible outside of the container at the volume mount
point of e.g. `typo3-root` which can be obtained by `inspect`ing
the container. The files, however, are owned by a system account and cannot be edited
by the current user, e.g.:

```bash
$ sudo ls -nA $(sudo docker volume inspect --format '{{.Mountpoint}}' typo3-root)

-rw-r--r--  1 100 101   1117 Mai  3 23:00 composer.json
-rw-r--r--  1 100 101 155056 Mai  3 23:01 composer.lock
drwxr-xr-x  6 100 101   4096 Mai  3 22:58 public
drwxrwsr-x  7 100 101   4096 Mai  3 23:02 var
drwxr-xr-x 15 100 101   4096 Mai  3 23:01 vendor
```

With Podman, files are owned by one of the current user's sub-UIDs which leads to
the same problem.

[bindfs](https://bindfs.org/) is a [FUSE](https://github.com/libfuse/libfuse#about)
filesystem that resolves this situation. It can provide a bind-mounted _view_ of
the files and directories in a volume with their UIDs and GIDs
mapped to your own UID and GID. This does not affect UIDs and GIDs seen by the
container.


### Setting the container environment

[Container environment variables](#container-environment-variables) control the
time zone inside the container, TYPO3 mode, PHP settings and Composer operation.

These variables can be set by `t3 run` option `--env`, e.g.

```bash
$ t3 run --env MODE=dev --env php_post_max_size=500K
```

Command `t3 env` can modify most settings also while the container is running,
e.g. in order to change the TYPO3 mode or to experiment with different `php.ini` settings:

```bash
$ t3 env MODE=xdebug php_post_max_size=1M
```

Container environment settings are lost when the container is stopped.


### Composer

Command `t3 composer` lets you manage your TYPO3 installation. It accepts
Composer command line options and is equivalent to running
[Composer](https://getcomposer.org/) _inside the container_,
e.g.

```bash
$ t3 composer require bk2k/bootstrap-package
```

`t3 composer` and the `composer` script found in the container always act
on the TYPO3 root directory.
Neither Composer nor PHP have to be installed on the host.

[XDebug should be deactivated](#activate-xdebug-in-the-container) before 
running Composer because it might slow down Composer significantly.


#### Preventing Composer from overwriting your changes

If you are continuing development of an extension which is already available
from a repository, then running `t3 composer update` may overwrite your changes
with the (older) version of that extension from the repository.

In order to prevent this, set the 
[container environment variable](#container-environment-variables) 
`COMPOSER_EXCLUDE` to a colon-separated list of _subdirectories_ of 
`/var/www/localhost` which are to be excluded from changes made by Composer.


### Debugging with XDebug

#### Set up your IDE for XDebug

-   PhpStorm et al.: [Debugging within a PHP Docker Container using IDEA/PhpStorm and Xdebug: Configure IntelliJ IDEA Ultimate or PhpStorm](https://phauer.com/2017/debug-php-docker-container-idea-phpstorm/#configure-intellij-idea-ultimate-or-phpstorm)
-   VSCode: install 
    [PHP Debug](https://github.com/felixfbecker/vscode-php-debug),
    add the following configuration to your `launch.json` file
    and start debugging with this configuration. If necessary, replace
    `typo3-root` with the actual [bindfs mount point](#using-an-ide) of
    the TYPO3 volume:

    ```json
    {
        "name": "Listen for XDebug from container",
        "type": "php",
        "request": "launch",
        "port": 9000,
        "pathMappings": {
            "/var/www/localhost": "${workspaceRoot}/typo3-root"
        }
    }
    ```


#### Install browser debugging plugins

Although not strictly required, debugging plugins make starting
a XDebug session more convenient.
[Browser Debugging Extensions](https://www.jetbrains.com/help/phpstorm/browser-debugging-extensions.html#Browser_Debugging_Extensions.xml)
lists recommended plugins for various browsers.


#### Activate XDebug in the container

Unless the container was started already with `--env MODE=xdebug` or
[host environment variable](#host-environment-variables) `T3_MODE=xdebug`,
this mode needs to be activated now:

```bash
$ t3 env MODE=xdebug
```

Now everything is ready to start a XDebug session.


### Accessing the TYPO3 database

#### SQLite

A working directory needs to be mounted as [described above](#using-an-ide).
Point your database client at the file `var/sqlite/cms-*.sqlite`
in that working directory.
This is the TYPO3 SQLite database. The actual filename contains a random part.


#### MariaDB and PostgreSQL

Unless configured differently by `t3 run` option `-P` or
[host environment variable](#host-environment-variables) `T3_DB_PORT`,
MariaDB is accessible at `127.0.0.1:3306` and PostgreSQL at `127.0.0.1:5432`.

The [database credentials](#database-credentials) are defined by host
environment variables.


### Managing multiple TYPO3 instances

To have multiple TYPO3 instances coexist, each instance must have
-   a unique container name (`t3 run` option `-n`), and
-   unique volume names or [work directories](#using-an-ide) (`t3 run` options `-v` 
    and `-V`).

If you wish to _run_ multiple TYPO3 instances simultaneously then each instance must
be mapped also to unique host ports (`t3 run` options `-p` and `-P`).
[Debugging](#debugging-with-xdebug) is possible in one instance at a time only.

Each `t3 stop`, `t3 composer` and `t3 env` command must be given an 
`-n` option to specify which TYPO3 instance should be targeted.


#### Suggested implementation

For each TYPO3 instance, create a configuration script which `export`s all required
options as [host environment variables](#host-environment-variables), e.g. 
`my-t3-conf`:

```bash
export T3_NAME=my-t3
export T3_ROOT=t3-root
export T3_PORT=127.0.0.1:8181
  ⁝
```

`source` the appropriate configuration script before issuing each `t3` command
and omit all options from the command, e.g.

```bash
$ source my-t3-conf && t3 run --
  ⁝
$ source my-t3-conf && t3 stop
```


## `t3` shell script reference

`t3`is a shell script for Linux and macOS for managing containerized TYPO3 instances.
`t3` command lines contain a command verb (what to do) and options (how to do it):

```bash
$ t3 COMMAND [option]...
```

The `t3` script is
[avaliable for download here](https://raw.githubusercontent.com/undecaf/typo3-dev/master/t3).
In order to view the version of this document that matches a running TYPO3 instance, 
point your browser to e.g. `http://localhost:8080/readme.html`.

Commands are described below.


### Getting help

This displays a list of available commands:

```bash
$ t3 -h
```

Getting help for a particular command:

```bash
$ t3 COMMAND -h
```


### `t3 run`

Configures and runs a TYPO3 container plus an optional MariaDB/PostgreSQL container:

```bash
$ t3 run [option]... [--] [Docker/Podman option]...
```

Although all
[options are optional](https://www.quora.com/What-is-the-meaning-of-no-pun-intended),
at least one option must be set (`--` is sufficient) as a precaution against 
inadvertent command invocation.

__Container engine:__
if you have both [Docker](https://www.docker.com/) and [Podman](https://podman.io/)
installed then option `-e` lets you choose between `docker` and `podman`.
Setting [host environment variable](#host-environment-variables) `T3_ENGINE`
relieves you from repeating that option for each `t3` command.

__Container name(s):__ the name of the TYPO3 container defaults to `typo3`.
Option `-n` and host environment variable `T3_NAME`
let you specify a different name. The database container name is derived from the 
TYPO3 container name by appending `-db`.

__TYPO3:__
by default, the latest image built for the most recent TYPO3 version is pulled
from [`docker.io/undecaf/typo3-dev`](https://hub.docker.com/r/undecaf/typo3-dev).
Option `-t` (or `T3_TAG`) selects a particular TYPO3 version and build by one of the
[available tags](https://hub.docker.com/r/undecaf/typo3-dev/tags).

TYPO3 is served at `127.0.0.1:8080` by default. Option `-p` (or `T3_PORT`) lets
you choose a different host interface and/or port.

__TYPO3 volume and work directory:__
The TYPO3 instance is saved in a persistent volume named `typo3-root`.
A different name can be assigned by option `-v` (or `T3_ROOT`). That name _must
not_ contain a `/`.

The TYPO3 volume can be made available for editing in a working directory at the host:
just specify the _working directory path_ (it _must_ contain a `/`) for option `-v` (or `T3_ROOT`).
This will have the following effects:

1.  The working directory basename becomes the TYPO3 volume name.
1.  The TYPO3 volume content appears in the working directory as if it were owned
    by the current user.
1.  File changes, creates and deletes will be passed in both directions between 
    working directory and container, with the current user's UID/GID mapped to container UIDs/GIDs.

Please note: using working directories requires the [bindfs](https://bindfs.org/)
(available for Debian-like and macOS hosts) utility to be installed from the repositories of your system.
For macOS, [osxfuse](https://osxfuse.github.io/) is needed beforehand.

__Database:__ by default, the SQLite instance of the TYPO3 image is used (works only
with TYPO3&nbsp;V9.5+). Option `-d` (or `T3_DB_TYPE`) lets
you use `mariadb` or `postgresql`, pulling the `latest` image from
[`docker.io/bitnami/mariadb`](https://hub.docker.com/r/bitnami/mariadb) or
[`docker.io/bitnami/postgresql`](https://hub.docker.com/r/bitnami/postgresql),
respectively.

Database state is saved in persistent volumes: SQLite is part of the TYPO3
volume, and MariaDB and PostgreSQL each use an additional volume named `typo3-data`.
Option `-V` (or `T3_DB_DATA`) sets a different volume name.

A new database is created whenever a database volume is used for the first time.
MariaDB and PostgreSQL database name and credentials are determined by host environment variables
`T3_DB_NAME`, `T3_DB_USER` and `T3_DB_PW`. If not set then they all default to `t3`.

To access an SQLite database from the host, a TYPO3 working directory must be
specified (see above). The database is located at `var/sqlite/cms-*.sqlite`
in that working directory. The actual filename contains a random part.

MariaDB and PostgreSQL databases are published to the host at `127.0.0.1:3306` and 
`127.0.0.1:5432` by default. Use the `-P` option (or `T3_DB_PORT`) to set a different
host interface and/or port.

__Container environment variables:__
control the time zone inside the container, TYPO3 mode, PHP settings and Composer operation; see [this table](#container-environment-variables) for details.

Use option `--env NAME=VALUE` or the corresponding
[host environment variable](#host-environment-variables) to assign an initial value to a container environment variable; `--env` takes precedence.

This option may appear multiple times. `--env` options must be the _last options_
on the command line.

The container environment can be changed at runtime by command [`t3 env`](#t3-env).

__Remove stopped container(s):__
add option `--rm` if the TYPO3 and the database container (if one exists) should be
removed by [`t3 stop`](#t3-stop). This option can also be used with `t3 stop`.

Please note: `t3` never removes _volumes_.
You have to use `docker/podman volume rm` to do that.

__Options to be passed to Docker/Podman:__
must be placed at the end of the 
command line and should be separated from `t3` options by `--`. Such options are
applied to both the TYPO3 and the database container (if one exists).


### `t3 stop`

Stops a running TYPO3 (and the associated database) container:

```bash
$ t3 stop [option]...
```

`t3 stop` will unmount a working directory mounted by [`t3 run`](#t3-run) or by
[`t3 mount`](#t3-mount).

Although all options are optional, at least one option must be set
(`--` is sufficient) as a precaution against inadvertent command invocation.

__Container engine:__
the same engine as for the corresponding `t3 run` command.
Use option `-e` (or `T3_ENGINE`) if necessary.

__Container name:__ 
the same container name as for the corresponding `t3 run` command.
Use option `-n` (or `T3_NAME`) if necessary.

__Remove stopped container(s):__
add option `--rm` if the TYPO3 and the database container (if one exists) should be
removed after being stopped. This option can also be used with [`t3 run`](#t3-run).


### `t3 env`

Modifies the environment of a running TYPO3 container by setting
[container environment variables](#container-environment-variables):

```bash
$ t3 env [option]... [NAME=VALUE]...
```

__Container engine:__
the same engine as for the corresponding `t3 run` command.
Use option `-e` (or `T3_ENGINE`) if necessary.

__Container name:__ 
the same container name as for the corresponding `t3 run` command.
Use option `-n` (or `T3_NAME`) if necessary.

__Container environment variables:__
control the time zone inside the container, TYPO3 mode, PHP settings and Composer operation; see [this table](#container-environment-variables) for details.

Use option `NAME=VALUE` to assign a value to a container environment variable.
This option may appear multiple times.

Initial values can be assigned by command [`t3 run`](#t3-run).


### `t3 composer`

Executes a [Composer](https://getcomposer.org/) command inside of a running
TYPO3 container:

```bash
$ t3 composer [option]... COMPOSER_CMD [Composer option]...
```
__Container engine:__
the same engine as for the corresponding `t3 run` command.
Use option `-e` (or `T3_ENGINE`) if necessary.

__Container name:__ 
the same container name as for the corresponding `t3 run` command.
Use option `-n` (or `T3_NAME`) if necessary.

__Composer command:__
the rest of the [Composer command line](https://getcomposer.org/doc/03-cli.md).
Composer is run in the context of the TYPO3 installation root in the container
(`/var/www/localhost`), i.e. the root of the TYPO3 volume.

In order to keep Composer from overwriting changes you made in your working
directory, set the 
[container environment variable](#container-environment-variables) 
`COMPOSER_EXCLUDE` to a colon-separated list of _subdirectories_ of 
`/var/www/localhost` which are to be excluded from changes made by Composer.


### `t3 mount`

Mounts a working directory to a container volume so that the volume
appears to be owned and can be managed by the current user:

```bash
$ t3 mount [--mount|-m] WORK_DIR [option]...
```
 
This is equivalent to [`t3 run`](#t3-run) with a working directory path for `-v`
except that the container does not need to be running (it does not even 
have to exist).

This command will ask for `sudo` authorization unless there are cached credentials.

__Container engine:__
the same engine as for the corresponding `t3 run` command.
Use option `-e` (or `T3_ENGINE`) if necessary.

__TYPO3 working directory:__
specify the _working directory path_ (it _must_ contain a `/`) for option `-m`.
The directory basename is taken as the volume name, and the working directory
is bind-mounted at that volume. This is equivalent to the `-v` option of
[`t3 run`](#t3-run) except that no container is needed for this operation.


### `t3 unmount`

Unmounts a working directory from the container volume:

```bash
$ t3 unmount [--unmount|-u] WORK_DIR [option]...
```

This command will ask for `sudo` authorization unless there are cached credentials.

__Container engine:__
the same engine as for the corresponding `t3 run` command.
Use option `-e` (or `T3_ENGINE`) if necessary.

__TYPO3 working directory:__
specify the _working directory path_ to unmount for option `-u`. This is what
is done automatically by [`t3 stop`](#t3-stop).


### Options

The following table shows which options are applicable to each command. It also
indicates which [host environment variable](#host-environment-variables)
contains the default value for each option and which default value is used if
that environment variable is not set.

| Option | Commands | Description |
|--------|----------|-------------|
| `--engine=ENGINE`<br>`-e ENGINE` | all | Container engine to use: `docker`, `podman` (can be) abbreviated, or an _absolute path_ to the engine executable.<br>Default:  `$T3_ENGINE`, or `podman` if installed, else `docker`. |
| `-h`<br>`--help` | none<br>all | Displays a list of commands, or help for the specified command. |
| `--name=NAME`<br>`-n NAME` | `run`<br>`stop`<br>`composer`<br>`env` | Container name. The database container name, if any, has `-db` appended to this name.<br>Default: `$T3_NAME`, or `typo3`. |
| `--hostname=HOSTNAME`<br>`-h HOSTNAME` | `run` | Hostname assigned to the TYPO3 container and to Apache `ServerName` and `ServerAdmin`.<br>Default: `$T3_HOSTNAME`, or `typo3.$(hostname)`. |
| `--tag=TAG`<br>`-t TAG` | `run` | Tag of image to run, consisting of TYPO3 version and build version, e.g. `8.7-1.3` or `9.5-latest`.<br> Default: `$T3_TAG`, or `latest`, i.e. the latest build for the most recent TYPO3 version. |
| `--typo3-root=VOLUME`<br>`-v VOLUME` | `run` | Either a volume name to be mapped to the TYPO3 root directory inside the container, or a working directory path (containing a `/`).<br>In the latter case, the directory basename is used as the volume name, and the directory is bind-mounted at that volume. Thus, volume content appears to be owned by the current user.<br>__Podman users please note:__ working directories require at least Podman&nbsp;v1.4.3.<br>Default: `$T3_ROOT`, or `typo3-root`. |
| `--typo3-port=PORT`<br>`-p PORT` | `run` | Host interface (optional) and port where to publish the TYPO3 HTTP port.<br>Default: `$T3_PORT`, or `127.0.0.1:8080`. |
| `--db-type=TYPE`<br>`-d TYPE` | `run`| Type of database container: `mariadb` for MariaDB or `postgresql` for PostgreSQL (can be abbreviated). If empty then the SQLite instance of the TYPO3 container will be used.<br>Default: `$T3_DB_TYPE`, or empty. |
| `--db-vol=VOLUME`<br>`-V VOLUME` | `run` | Database volume name; requires option `--db-type`.<br>Defaults: `$T3_DB_DATA`, or `typo3-data`. |
| `--db-port=PORT`<br>`-P PORT` | `run` | Host interface (optional) and port where to publish the database port; requires option `--db-type`.<br> Defaults: `$T3_DB_PORT`, or `127.0.0.1:3306` for MariaDB and `127.0.0.1:5432` for PostgreSQL. |
| `--rm` | `run`<br>`stop` | Causes the TYPO3 container and the respective database container (if one exists) to be removed after they were stopped. |
| `--env NAME=VALUE` | `run` | Sets the (initial) value of a [container environment variable](#container-environment-variables), eventually overriding the corresponding [host environment variable](#host-environment-variables). The values of most variables can be changed afterwards by `t3 env`.<br>This option may appear multiple times. `--env` options must be the _last options_ on the command line. |
| `--mount=WORKDIR`<br>`-m WORKDIR` | `mount` | Path of a working directory to bind-mount to a persistent volume. The basename of this path is taken as the name of the persistent volume. |
| `--unmount=WORKDIR`<br>`-u WORKDIR` | `unmount`| Absolute path of the directory to unmount from a persistent volume. |


### Host environment variables

These variables can be set in the host shell and are intended for setting
custom default values for [options](#options) and
[container environment variables](#container-environment-variables),
thus establishing a consistent environment for all `t3` commands.


| Name | Description | Built-in default |
|------|-------------|------------------|
| `T3_ENGINE` | Container engine to use: `docker`, `podman` (can be) abbreviated, or an _absolute path_ to the engine executable. | `podman` if installed, else `docker` |
| `T3_NAME` | Container name. The database container name, if any, has `-mariadb` or `-postgresql` appended to this name. | `typo3` |
| `T3_HOSTNAME` | Hostname assigned to the TYPO3 container and to Apache `ServerName` and `ServerAdmin`. | `typo3.$(hostname)` |
| `T3_TAG` | Tag of image to run, consisting of TYPO3 version and build version, e.g. `8.7-1.3` or `9.5-latest`. | `latest` |
| `T3_ROOT` | Volume name to be mapped to the TYPO3 root directory inside the container.<br>If an absolute directory path specified then its basename is used as the volume name; in addition, that directory is bind-mounted at the volume so that files and directories in that volume  appear to be owned by the current user. | `typo3-root` |
| `T3_PORT` | Interface (optional) and port where to publish the TYPO3 HTTP port. | `127.0.0.1:8080` |
| `T3_DB_TYPE` | Type of database container: `mariadb` for MariaDB or `postgresql` for PostgreSQL (can be abbreviated). If empty then the SQLite instance of the TYPO3 container will be used. | empty |
| `T3_DB_DATA`| Database volume name; effective only if `T3_DB_TYPE` or `--db-type` is set. | `typo3-data` |
| `T3_DB_PORT` | Host interface (optional) and port where to publish the database port; effective only if `T3_DB_TYPE` or `--db-type` is set. | `127.0.0.1:3306`, or<br>`127.0.0.1:5432` |
| `T3_DB_NAME` | Name of the TYPO3 database that is created automatically by `t3 run`. | `t3` |
| `T3_DB_USER` | Name of the TYPO3 database owner. | `t3` |
| `T3_DB_PW` | Password of the TYPO3 database. | `t3` |
| `T3_DB_ROOT_PW` | Password of the MariaDB root user. | `toor` |
| `T3_TIMEZONE`<br>`T3_MODE`<br>`T3_COMPOSER_EXCLUDE`<br>`T3_PHP_...`<br>`T3_php_...` | Initial values for [container environment variables](#container-environment-variables) `TIMEZONE`, `MODE`, `COMPOSER_EXCLUDE`, `PHP_...` and `php_...`. | empty |



### Container environment variables

These variables can get their initial values from 
[host environment variables](#host-environment-variables) or 
from the `t3 run --env` option; the `--env` option takes precedence.

Except for `TIMEZONE`, these variables can be set or changed at runtime by
the `t3 env` command.

| Name | Description | Built-in default |
|------|-------------|------------------|
| `TIMEZONE` | Sets the TYPO3 container timezone (e.g. `Europe/Vienna`). |Timezone of your current location, or else UTC. |
| `MODE`| <dl><dt>`prod`</dt><dd>selects production mode: TYPO3 operating in „Production Mode“, no Apache/PHP signature headers, PHP settings as per     [`php.ini-production`](https://github.com/php/php-src/blob/master/php.ini-production)</dd><dt>`dev`</dt><dd>selects development mode: TYPO3 in „Development Mode“, verbose Apache/PHP signature headers, PHP settings as recommended by [`php.ini-development`](https://github.com/php/php-src/blob/master/php.ini-development)</dd><dt>`xdebug`</dt><dd>selects development mode as above and also enables [XDebug](https://xdebug.org/)</dd></dl> | `prod` |
| `COMPOSER_EXCLUDE` | Colon-separated list of _subdirectories_ of `/var/www/localhost` which are to be excluded from the effects of [Composer operations](#composer).<br>This is intended e.g. to protect the current version of an extension you are developing from being overwritten by an older version stored in a repository.<br>These directories need to exist only by the time Composer is invoked. | empty |
| `PHP_...`<br>`php_...` | Environment variables prefixed with `PHP_` or `php_` become `php.ini` settings with the prefix removed, e.g. `--env php_post_max_size=5M` becomes `post_max_size=5M`. These settings override prior settings and `MODE`. | none |


## Credits

TODO


## Licenses

Scripts in this repository are licensed under the GPL&nbsp;3.0.

This document is licensed under the Creative Commons license CC&nbsp;BY-SA&nbsp;3.0.

As for any pre-built image usage, it is the image user's responsibility to ensure that any use of this image
complies with any relevant licenses for all software contained within.
More information on this subject may be found in
[this discussion](https://opensource.stackexchange.com/questions/7013/license-for-docker-images#answer-7015).
