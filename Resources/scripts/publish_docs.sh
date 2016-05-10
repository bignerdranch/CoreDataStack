#!/bin/bash

if [ "$TRAVIS_PULL_REQUEST" == "false" ] && [ "$TRAVIS_BRANCH" == "master" ]; then
    echo -e "Generating docs \n"

    echo -e "Creating gh-pages dir \n"
    mkdir gh-pages

    echo -e "Moving into gh-pages clone \n"
    pushd gh-pages

    echo -e "Creating gh-pages repo \n"
    git config --global user.email "travis@travis-ci.org"
    git config --global user.name "travis-ci"
    git init

    echo -e "Generating Jazzy output \n"
    bundle exec jazzy --podspec ../BNRCoreDataStack.podspec -m "CoreDataStack" --config .jazzy.yml
    
    echo -e "Adding new docs \n"
    git add -A
    git commit -m "Refresh docs from successful travis build $TRAVIS_BUILD_NUMBER"
    git push --force --quiet "https://${GH_TOKEN}@github.com/bignerdranch/CoreDataStack" master:gh-pages > /dev/null 2>&1
    echo -e "Published latest docs.\n"

    echo -e "Moving out of gh-pages clone and cleaning up"
    popd
fi
