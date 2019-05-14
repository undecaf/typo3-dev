#!/bin/bash

USAGE=$(cat <<-EOF

Runs the undecaf/typo3-dev TYPO3 container in Docker or Podman.

Usage:
  $(basename $0) [-e engine] [-n name] [-p [ip:]port] [-t t3-build] [-v volume] [docker/podman option]...
  $(basename $0) -h

Options (default values can be overridden by environment variables):
  -e engine     Container engine to use: 'docker', 'podman' or an absolute path to the
                engine executable. 
                Default: TYPO3DEV_ENGINE, or 'podman' if installed, else 'docker'.
  -n name       Container name to assign. Default: TYPO3DEV_NAME, or 'typo3'.
  -p [ip:]port  Host IP and port where to publish the TYPO3 HTTP port.
                Default: TYPO3DEV_PUBLISH, or 127.0.0.1:8080.
  -t t3-build   Tag of image to run, consisting of TYPO3 version and build version,
                e.g. '8.7-1.3' or '9.5-latest'.
                Default: TYPO3DEV_TAG, or 'latest', i.e. the latest build for the most recent
                TYPO3 version.
  -v volume     Volume name or absolute directory path to be mapped to the TYPO3 root directory
                inside the container. Default: TYPO3DEV_VOLUME, or 'typo3-vol'.
  -h            Displays this text and exits.
 
EOF
)

. $(dirname $0)/utils.sh

set -x

$ENGINE run \
    --detach \
    $REMOVE_OPT \
    --name $NAME \
    --hostname dev.typo3.local \
    $HOST_IP_OPT \
    --volume $VOLUME:$TYPO3_ROOT \
    --publish $PUBLISH:80 \
    $@ \
    $REPO_SLUG${TAG:+:$TAG}
