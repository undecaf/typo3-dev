#!/bin/bash

echo '*************** '"TYPO3_VER: '$TYPO3_VER'"
echo '*************** '"TRAVIS_TAG: '$TRAVIS_TAG'"
echo '*************** '"IMAGE_VER: '${TRAVIS_TAG:-latest}'"

docker build \
    --pull \
    --cache-from $TRAVIS_REPO_SLUG \
    --build-arg TYPO3_VER=$TYPO3_VER \
    --build-arg IMAGE_VER=${TRAVIS_TAG:-latest} \
    --tag $TRAVIS_REPO_SLUG \
    .

for T in $(.travis/tags.sh); do 
    echo '*************** '"Tagging $TRAVIS_REPO_SLUG as $TRAVIS_REPO_SLUG:$T"
    docker tag $TRAVIS_REPO_SLUG $TRAVIS_REPO_SLUG:$T
done
