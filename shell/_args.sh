#!/bin/bash

#
# Provides commonly used functions and environment variables.
#
# Usage: source _args.sh $@ (pass the caller's command line arguments)
#


# --------------------------------------------------------------------------

# Prints $USAGE and an optional error message to stdout or stderr
# and exits with error code 0 or 1, respectively.
#
# Arguments:
#   $1  (optional) error message: if specified then it is printed, and all
#       output is sent to stderr; otherwise $USAGE goes to stdout.
# Requires:
#   $USAGE usage information; preserving linefeeds in $USAGE:
#       USAGE=$(cat <<-EOF
#           ... multiline text ...
#       EOF
#       )
#
usage() {
    local SCRIPT=$(basename $0)
    local REDIR=
    local EXIT_CODE=0

    if [ -n "$1" ]; then
        cat >&2 <<- EOF

*** $1 ***
EOF
        REDIR=">&2"
    EXIT_CODE=1
    fi

    eval 'echo "$USAGE" '$REDIR
    exit $EXIT_CODE
}

# --------------------------------------------------------------------------

# Constants
REPO_SLUG=undecaf/typo3-dev
TYPO3_ROOT=/var/www/localhost

# Default options, overridden by environment variables
TAG=${TYPO3DEV_TAG:-latest}
ENGINE=${TYPO3DEV_ENGINE:-$(which podman)} || ENGINE=docker
NAME=${TYPO3DEV_NAME:-typo3}
T3_VOL=${TYPO3DEV_ROOT:-typo3-vol}
DB_TYPE=
DB_VOL=

# Process command line options (only ALLOWED_OPTS if this variable exists)
while getopts :${ALLOWED_OPTS:-d:e:n:t:v:w:}h- OPT; do
    case "$OPT" in
        # Database type
        d)
            DB_TYPE=
            [ "$OPTARG" = m ] && DB_TYPE=mariadb
            [ "$OPTARG" = p ] && DB_TYPE=postgresql
            [ -z "$DB_TYPE" ] && usage "Unknown database type: '$OPTARG'"
            ;;

        # Container engine
        e)
            ENGINE=$OPTARG  # basename or absolute path of an executable
            ;;

        # Container name
        n)
            NAME=$OPTARG
            ;;

        # Image tag
        t)
            TAG=$OPTARG
            ;;

        # TYPO3 or database volume (volume name or absolute path)
        v|w)
            RE='^/.+'
            [[ "$OPTARG" =~ $RE ]] && [ ! -d "$OPTARG" ] && usage "Directory '$OPTARG' given for volume but not found"
            case $OPT in
                v)
                    T3_VOL=$OPTARG
                    ;;
                w)
                    DB_VOL=$OPTARG
                    ;;
            esac
            ;;

        # Help
        h)
            usage
            ;;

        # First long option to be passed through to the engine
        -)
            break
            ;;

        # First short option to be passed through to the engine
        \?)
            OPTIND=$((OPTIND-1))  # prevent this option from being skipped
            break
            ;;
    esac
done

shift $((OPTIND-1))

# Validate container engine option
[ -x "$(which $ENGINE)" ] || usage "Container engine '$ENGINE' not found or not excutable"

ENGINE=$(which $ENGINE)
ENGINE_NAME=$(basename $ENGINE)

# Validate database type if database volume was specified
[ -n "$DB_VOL" ] && [ -z "$DB_TYPE" ] && usage "Database type is missing"

# Eventually set a default value for the database volume
if [ -n "$DB_TYPE" -a -z "$DB_VOL" ]; then
    DB_VOL=${TYPO3DEV_DB:-${DB_TYPE}-vol}
fi

# Settings that differ between container engines
case $ENGINE_NAME in
    docker)
        HOST_IP_ENV=
        HOST_IP_OPT=
        REMOVE_OPT=--rm
        MP_FORMAT='{{.Mountpoint}}'
        SUDO_PREFIX=sudo
        ;;

    podman)
        HOST_IP_ENV="HOST_IP=$(hostname -I | awk '{print $1}')"
        HOST_IP_OPT="--env $HOST_IP_ENV"
        REMOVE_OPT=  # temporary workaround until #3071 fixed
        MP_FORMAT='{{.MountPoint}}'
        SUDO_PREFIX=
        ;;
esac