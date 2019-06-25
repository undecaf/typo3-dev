#!/bin/bash

export IMAGE_VER=${TRAVIS_TAG:-latest}

echo '*************** '"TYPO3_VER: '$TYPO3_VER'"
echo '*************** '"TRAVIS_TAG: '$TRAVIS_TAG'"
echo '*************** '"IMAGE_VER: '$IMAGE_VER'"

set -x

docker build \
    --pull \
    --cache-from $TRAVIS_REPO_SLUG \
    --build-arg TYPO3_VER=$TYPO3_VER \
    --build-arg IMAGE_VER=$IMAGE_VER \
    --tag $TRAVIS_REPO_SLUG \
    .

set +x

for T in $(.travis/tags.sh); do 
    echo '*************** '"Tagging $TRAVIS_REPO_SLUG as $TRAVIS_REPO_SLUG:$T"
    docker tag $TRAVIS_REPO_SLUG $TRAVIS_REPO_SLUG:$T
done
