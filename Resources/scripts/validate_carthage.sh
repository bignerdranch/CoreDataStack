#!/bin/bash
# 
# Bootstraps Carthage to validate that everything builds as expected.
# thanks to abbeycode/UnzipKit for example 
#

EXIT_CODE=0

clone_project() {
  local BRANCH_NAME
  local CLONE_URL="https://github.com/bignerdranch/CoreDataStack.git"
  if [[ $CIRCLECI ]]; then
    BRANCH_NAME=$CIRCLE_BRANCH
  elif [[ $TRAVIS ]]; then
    if [ "$TRAVIS_PULL_REQUEST" != "false" ]; then
        BRANCH_NAME=$TRAVIS_PULL_REQUEST_BRANCH
        echo "Testing Pull Request Branch: \"$TRAVIS_PULL_REQUEST_BRANCH\""
        if [ "$TRAVIS_PULL_REQUEST_SLUG" != "$TRAVIS_REPO_SLUG" ]; then
          echo "Testing a fork. Skip Carthage validation."
          exit 0
        fi
      else
        BRANCH_NAME=$TRAVIS_BRANCH
        echo "Testing Branch: \"$TRAVIS_BRANCH\""
    fi
  else
    BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD)
    echo "=================Not Running in CI================="
  fi

  echo "=================Creating Cartfile================="
  echo "git \"$CLONE_URL\" \"$BRANCH_NAME\"" > ./Cartfile
  less -FX ./Cartfile
}

bootstrap() {
  echo "=================Bootstrapping Carthage================="
  carthage bootstrap --configuration Debug --verbose --toolchain "com.apple.dt.toolchain.Swift_3_0"
  EXIT_CODE=$?
}

validate() {
  echo "=================Checking for build products================="

  if [ ! -d "Carthage/Build/iOS/CoreDataStack.framework" ]; then
    echo "=================iOS Library failed to build with Carthage================="
    EXIT_CODE=1
  fi

  if [ ! -d "Carthage/Build/tvOS/CoreDataStack.framework" ]; then
    echo "=================iOS Library failed to build with Carthage================="
    EXIT_CODE=1
  fi
}

clean_up() {
  echo "=================Cleaning Up================="
  rm ./Cartfile
  rm ./Cartfile.resolved
  rm -rf ./Carthage
}

clone_project
bootstrap
validate
clean_up
exit $EXIT_CODE
