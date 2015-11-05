#!/bin/bash

set -x

if [ "$TRAVIS_PULL_REQUEST" == "false" ] && [ "$TRAVIS_BRANCH" == "master" ]; then
    echo -e "Generating docs \n"

    echo -e "Cloning gh-pages branch \n"
    git config --global user.email "travis@travis-ci.org"
    git config --global user.name "travis-ci"
    git clone --quiet --branch=gh-pages https://${GH_TOKEN}@github.com/bignerdranch/CoreDataStack gh-pages > /dev/null

    echo -e "Installing Jazzy \n"
    gem install jazzy

    echo -e "Generating Jazzy output \n"
    jazzy --swift-version 2.1 --source-directory ./ --output ./gh-pages --podspec ./BNRCoreDataStack.podspec

    echo -e "Moving into gh-pages clone"
    pushd gh-pages

    echo -e "Adding new docs \n"
    git --version
    git add -A
    git status
    git commit -m "Refresh docs from successful travis build $TRAVIS_BUILD_NUMBER"
    git push -fq origin gh-pages > /dev/null

    echo -e "Moving out of gh-pages clone and cleaning up"
    popd

    echo -e "Published latest docs.\n"
fi
