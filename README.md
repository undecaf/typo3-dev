# TYPO3 CMS for Docker and Podman

Provides a containerized TYPO3 installation equivalent to
[`composer require typo3/cms`](https://packagist.org/packages/typo3/cms) with
[ImageMagick](https://www.imagemagick.org/) and configured for
[Composer Mode](https://wiki.typo3.org/Composer#Composer_Mode).

The image is based on [Alpine Linux](https://alpinelinux.org/), Apache and
PHP&nbsp;7 and is quite compact (280&nbsp;MB).

It can be linked to a MySQL or a PostgreSQL container and can be run even as a
standalone container using the built-in SQLite database.

# Building

In order to build the image with [Docker](https://www.docker.com/) and name it
`localhost/typo3-composer`:

```bash
docker build --tag typo3-composer git://github.com/undecaf/typo3-composer
```

If you prefer working rootless with [Podman](https://podman.io/) then substitute `podman` in all `docker` commands (unless you have set `alias docker=podman`).


# Running

## Quick & dirty

This creates a TYPO3 instance in a standalone container, maintaining database
and website state in volumes `sqlite-vol` and `typo3-vol`:
```bash
docker run -d \
    -v sqlite-vol:/var/www/localhost/var/sqlite \
    -v typo3-vol:/var/www/localhost/public \
    -p 127.0.0.1:8080:80 \
    typo3-composer
```

Browsing to `http://localhost:8080` starts the TYPO3 installation wizard. 
When asked to select a database, choose `Manually configured SQLite connection` and
continue through the remaining dialogs to the TYPO3 login dialog.

### Volume structure

-   `/var/www/localhost/public`: TYPO3 document root. Note that
    `composer.json` is located in the parent directory and can be accessed only [through a shell](#shell-access-and-composer).
-   `/var/www/localhost/var/sqlite`: contains the TYPO3 SQLite database, or is empty
    for MariaDB and PostgreSQL.

## Reliable: MariaDB and PostgreSQL

The following examples show how to employ MariaDB
([`bitnami/mariadb`](https://hub.docker.com/r/bitnami/mariadb)) as the TYPO3
database. PostgreSQL ([`bitnami/postgresql`](https://hub.docker.com/r/bitnami/postgresql)) configuration is not shown here as it is quite similar.

Starting database and TYPO3 containers separately but with a common network
stack: `127.0.0.1` is shared _within_ containers but is separate from the host's
`127.0.0.1`.

```bash
# Start MariaDB container, must expose TYPO3 port now for later
podman run -d \
    --name mariadb \
    -e MARIADB_DATABASE=t3 -e MARIADB_USER=t3 \
    -e MARIADB_PASSWORD=t3 -e MARIADB_ROOT_PASSWORD=toor \
    -v mariadb-vol:/bitnami/mariadb \
    -p 127.0.0.1:3306:3306 \
    -p 127.0.0.1:8080:80 \
    bitnami/mariadb

# Start TYPO3 container, join MariaDB network namespace
podman run -d \
    -v typo3-vol:/var/www/localhost/public \
    --net container:mariadb \
    typo3-composer
```


## Runtime configuration

`--hostname` determines both the container hostname and the Apache `ServerName` and `ServerAdmin`.
If `--hostname` is omitted then the container gets a random hostname, and `ServerName` 
defaults to `localhost`.

`--env` variables that are recognized at runtime:

-   `TIMEZONE`: sets the container timezone (e.g. `Europe/Vienna`), defaults to UTC.

-   `MODE`:
    -   `dev` selects development mode, i.e. TYPO3 in „Development Mode“, 
        verbose Apache/PHP signature headers, PHP settings as recommended by
        [`php.ini-development`](https://github.com/php/php-src/blob/master/php.ini-development)
    -   `prod` selects production mode: TYPO3 in „Production Mode“, no Apache/PHP
        signature headers, PHP settings as per
        [`php.ini-production`](https://github.com/php/php-src/blob/master/php.ini-production)

-   `XDEBUG_ENABLED`: enables [XDebug](https://xdebug.org/) if set to anything
    non-empty. Not recommended for production mode.

-   `PHP_...`: environment variables prefixed with `PHP_` or `php_` become `php.ini`
    settings with the prefix removed, e.g. `--env php_post_max_size=5M` becomes 
    `post_max_size=5M`. These settings override prior settings and `MODE`.


## Shell access and `composer`

This opens a `root` shell in a running container:
```bash
docker exec -it <container-id> bash
```
You can also run the container with a `root` shell that is open from the beginning.
In this case you have to start Apache yourself (command `httpd`):
```bash
docker run <args described above> -it typo3-composer bash
```

Shell access is required for managing the TYPO3 installation with
[Composer](https://wiki.typo3.org/Composer).
The `composer` command has been customized for this use case, in particular:
-   `composer` always uses `/var/www/localhost` as working directory
    (i.e. the location of `composer.json` for TYPO3), 
    even if the command is run in a different directory.
-   Directories and files created by `composer` are owned by the Apache daemon
    although the command is run by `root`.

Thus, `composer` guarantees that packages will be installed at the correct locations
and with correct ownership.
