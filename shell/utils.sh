#!/bin/bash

#
# Provides commonly used functions and environment variables.
#
# Usage: source utils.sh $@ (pass the caller's command line arguments)
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
PUBLISH=${TYPO3DEV_PUBLISH:-127.0.0.1:8080}
VOLUME=${TYPO3DEV_VOLUME:-typo3-vol}

# Process command line options (only ALLOWED_OPTS if this variable exists)
while getopts :${ALLOWED_OPTS:-e:n:p:t:v:}h- OPT; do
    case "$OPT" in
        # Container engine
        e)
            ENGINE=$OPTARG  # basename or absolute path of an executable
            ;;

        # Container name
        n)
            NAME=$OPTARG
            ;;

        # TYPO3 interface and port
        p)
            PUBLISH=$OPTARG  # [interface:]port
            RE='^(([0-9]+\.){3}[0-9]+:)?[0-9]+$'
            [[ "$PUBLISH" =~ $RE ]] || usage "Invalid port to publish at: '$PUBLISH'"
            ;;

        # Image tag
        t)
            TAG=$OPTARG
            ;;

        # TYPO3 volume
        v)
            VOLUME=$OPTARG  # volume name or absolute path
            RE='^/.+'
            [[ "$VOLUME" =~ $RE ]] && [ ! -d "$VOLUME" ] && usage "Volume directory '$VOLUME' not found"
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