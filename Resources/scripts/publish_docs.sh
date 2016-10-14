#!/bin/bash

DOCS_DIR="docs"

generate_docs() {
    echo -e "Generating docs \n"

    local MASTER_BRANCH="master"
    local BUILD_DIR BRANCH_NAME
    local IS_PR=false

    if [[ $CIRCLECI ]]; then
        BRANCH_NAME=$CIRCLE_BRANCH
        BUILD_DIR=$(pwd)
        IS_PR=$CI_PULL_REQUEST
    elif [[ $TRAVIS ]]; then
        BRANCH_NAME=$TRAVIS_BRANCH
        BUILD_DIR=$TRAVIS_BUILD_DIR
        IS_PR=$TRAVIS_PULL_REQUEST
    else
        BUILD_DIR="$HOME/workspace/CoreDataStack"
        BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD)
        MASTER_BRANCH=$BRANCH_NAME
        echo "=================Not Running in CI================="
    fi

    echo "Current Branch: $BRANCH_NAME"
    echo "Is this a PR: $IS_PR"

    if [ "$IS_PR" == "false" ]; then
        if [[ $BRANCH_NAME = "$MASTER_BRANCH" ]]; then
            echo -e "Generating Jazzy output \n"
            bundle exec jazzy --output "$BUILD_DIR"/"$DOCS_DIR" --clean --config "$BUILD_DIR"/.jazzy.yml
        else
            echo "Aborting doc generation. Not on master branch." 1>&2
            exit 1
        fi
    else
        echo "Aborting doc generation. This is a pull request" 1>&2
        exit 1
    fi
}

commit_changes() {
    local build_num, gitRemoteURL, commitMessage
    if [[ $CIRCLECI ]]; then
        build_num=$CIRCLE_BUILD_NUM
        # gitRemoteURL="https://${GH_TOKEN}@github.com/bignerdranch/CoreDataStack"
        # commitMessage = "Refresh docs from successful ci build $build_num"
        echo "=================CIRCLECI Not Configured for Doc Pushing================="
        exit 1
    elif [[ $TRAVIS ]]; then
        build_num=$TRAVIS_BUILD_NUMBER
        gitRemoteURL="https://${GH_TOKEN}@github.com/bignerdranch/CoreDataStack"
        commitMessage="Refresh docs from successful ci build $build_num"
    else
        build_num=false
        gitRemoteURL="https://github.com/bignerdranch/CoreDataStack"
        commitMessage="Manually refreshing docs from \"$HOSTNAME\""
    fi

    echo -e "Moving into docs directory \n"
    pushd $DOCS_DIR

    git init

    local username="ci"
    local email="ci@bignerdranch.com"
    if [[ $CIRCLECI ]]; then
        git config user.email "$email"
        git config user.name "$username"
    elif [[ $TRAVIS ]]; then
        git config user.email "$email"
        git config user.name "$username"
    fi

    echo -e "Adding new docs \n"
    git add -A
    git commit -m "$commitMessage"
    git push --force --quiet "$gitRemoteURL" master:gh-pages > /dev/null 2>&1
    echo -e "Published latest docs.\n"

    echo -e "Moving out of gh-pages clone and cleaning up"
    popd
}

generate_docs
commit_changes
