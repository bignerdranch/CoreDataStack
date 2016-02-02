#!/bin/bash
# 
# Bootstraps Carthage to validate that everything builds as expected.
# thanks to abbeycode/UnzipKit for example 
#

if [ -z ${TRAVIS+x} ]; then
    TRAVIS_BUILD_DIR="/Users/redwards/workspace/CoreDataStack"
    TRAVIS_BRANCH="rcedwards/testability_fix"
fi

echo "=================Creating Cartfile================="
echo "git \"$TRAVIS_BUILD_DIR\" \"$TRAVIS_BRANCH\"" > ./Cartfile

echo "=================Bootstrapping Carthage================="
carthage bootstrap --configuration Debug
EXIT_CODE=$?

echo "=================Checking for build products================="

if [ ! -d "Carthage/Build/iOS/CoreDataStack.framework" ]; then
    echo "=================iOS Library failed to build with Carthage================="
    EXIT_CODE=1
fi

if [ ! -d "Carthage/Build/tvOS/CoreDataStack.framework" ]; then
    echo "=================iOS Library failed to build with Carthage================="
    EXIT_CODE=1
fi

echo "=================Cleaning Up================="
rm ./Cartfile
rm ./Cartfile.resolved
rm -rf ./Carthage

exit $EXIT_CODE
