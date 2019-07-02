#!/bin/bash

# Runs t3 with the specified arguments and echoes the command line to stdout.
t3() {
    set -x
    ./t3 $@
    { set +x; } 2>/dev/null
}

# Echoes to stdout the number of containers whose names match the specified RE.
count_containers() {
    docker container ls --filter name='^/'"$1"'$' --format='{{.Names}}' | wc -l
}

# Echoes to stdout the number of volumes whose names match the specified RE.
count_volumes() {
    docker volume ls --filter name='^'"$1"'$' --format='{{.Name}}' | wc -l
}


echo $'\n********************* Testing'

# TODO: Use the tag that was just built
# Extract MAJOR.MINOR of $TRAVIS_TAG
RE='^([0-9]+\.[0-9]+)(\..+)?'
[[ "$TRAVIS_TAG" =~ $RE ]] && TAG=$TYPO3_VER-${BASH_REMATCH[1]} || TAG=${TYPO3_VER}-latest

set -e

# Will stop any configuration
trap './t3 stop --rm' EXIT

# TYPO3 standalone
t3 run -t $TAG

[ $(count_containers 'typo3') -eq 1 ] || exit 1
[ $(count_containers 'typo3-db') -eq 0 ] || exit 1
[ $(count_volumes 'typo3-root') -eq 1 ] || exit 1
[ $(count_volumes 'typo3-data') -eq 0 ] || exit 1

t3 stop --rm

[ $(count_containers 'typo3(-db)?') -eq 0 ] || exit 1
[ $(count_volumes 'typo3-root') -eq 1 ] || exit 1

docker volume rm typo3-root

# TYPO3 + MariaDB
t3 run -d mariadb -t $TAG

[ $(count_containers 'typo3(-db)?') -eq 2 ] || exit 1
[ $(count_volumes 'typo3-(root|data)') -eq 2 ] || exit 1

t3 stop --rm

[ $(count_containers 'typo3(-db)?') -eq 0 ] || exit 1
[ $(count_volumes 'typo3-(root|data)') -eq 2 ] || exit 1

docker volume rm typo3-root
docker volume rm typo3-data

