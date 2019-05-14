#!/bin/bash

USAGE=$(cat <<-EOF

Modifies the environment of a TYPO3 container running in Docker or Podman.

Usage:
  $(basename $0) [-e engine] [-n name] [VAR=value]...
  $(basename $0) -h

Options (default values can be overridden by environment variables):
  -e engine     Container engine to use: 'docker', 'podman' or an absolute path to the
                engine executable. 
                Default: TYPO3DEV_ENGINE, or 'podman' if installed, else 'docker'.
  -n name       Container name. Default: TYPO3DEV_NAME, or 'typo3'.
  -h            Displays this text and exits.
 
EOF
)

ALLOWED_OPTS=e:n:

. $(dirname $0)/utils.sh

set -x

$ENGINE exec $NAME setenv $HOST_IP_ENV $@
