#!/bin/bash

if [ "$TRAVIS_BRANCH" = master ]; then
    export IMAGE_VER=latest
else
    export IMAGE_VER=$TRAVIS_BRANCH
fi

echo '*************** '"TRAVIS_BRANCH: '$TRAVIS_BRANCH'"
echo '*************** '"TRAVIS_COMMIT: '$TRAVIS_COMMIT'"
echo '*************** '"TRAVIS_TAG: '$TRAVIS_TAG'"
echo '*************** '"TYPO3_VER: '$TYPO3_VER'"
echo '*************** '"IMAGE_VER: '$IMAGE_VER'"

set -x

docker build \
    --build-arg COMMIT=$TRAVIS_COMMIT \
    --build-arg TYPO3_VER=$TYPO3_VER \
    --build-arg IMAGE_VER=$IMAGE_VER \
    --tag $TRAVIS_REPO_SLUG \
    .

set +x

#    --pull \
#    --cache-from $TRAVIS_REPO_SLUG \

for T in $(.travis/tags.sh); do 
    echo '*************** '"Tagging $TRAVIS_REPO_SLUG as $TRAVIS_REPO_SLUG:$T"
    docker tag $TRAVIS_REPO_SLUG $TRAVIS_REPO_SLUG:$T
done
