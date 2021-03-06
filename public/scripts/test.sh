#!/bin/sh -l

echo "๐ Igniting...3 2 1"

echo "โ๏ธ Changing the gears"

GIT_USER_EMAIL="${INPUT_GIT_USER_EMAIL:-'github-action@users.noreply.github.com'}"
GIT_USER_NAME="${INPUT_GIT_USER_NAME:-'GitHub Action'}"
git config --global user.email "$GIT_USER_EMAIL"
git config --global user.name "$GIT_USER_NAME"

ACCESS_TOKEN="$INPUT_ACCESS_TOKEN"
TARGET_OWNER="$INPUT_TARGET_OWNER"
TARGET_REPO="$INPUT_TARGET_REPO"
TARGET_BRANCH="${INPUT_TARGET_BRANCH:-master}"
CLEANUP_COMMAND="$INPUT_CLEANUP_COMMAND"
SRC_DIR="$INPUT_SRC_DIR"
TARGET_DIR="$INPUT_TARGET_DIR"
PRECOMMIT_COMMAND="$INPUT_PRECOMMIT_COMMAND"

REPOSITORY="$TARGET_OWNER/$TARGET_REPO"

# If access token is provided, use it
if [ ! -z "$ACCESS_TOKEN" ]; then
    REPO_PATH="https://$ACCESS_TOKEN@github.com/$REPOSITORY.git"
else
    # otherwise it's assumed that SSH is already set up
    REPO_PATH="git@github.com:$REPOSITORY.git"
fi

echo "โฌ๏ธ Cloning $REPOSITORY"
CLONE_DIR="__${TARGET_REPO}__clone__"
cd $GITHUB_WORKSPACE
# Ensure that the clone path is clean
rm -rf $CLONE_DIR/*
git clone -b $TARGET_BRANCH $REPO_PATH $CLONE_DIR

echo "๐งน Housekeeping"
cd $GITHUB_WORKSPACE/$CLONE_DIR
eval "$CLEANUP_COMMAND"

echo "โณ Copying files from $SRC_DIR"
# Make sure the directory exists after clean up
mkdir -p $GITHUB_WORKSPACE/$CLONE_DIR/$TARGET_DIR

# If the source is a directory
if [ -d "$GITHUB_WORKSPACE/$SRC_DIR" ]; then
    cp -r $GITHUB_WORKSPACE/$SRC_DIR/* $GITHUB_WORKSPACE/$CLONE_DIR/$TARGET_DIR
else
    cp -r $GITHUB_WORKSPACE/$SRC_DIR $GITHUB_WORKSPACE/$CLONE_DIR/$TARGET_DIR
fi

echo "๐ก Running pre-commit command"
cd $GITHUB_WORKSPACE/$CLONE_DIR
eval "$PRECOMMIT_COMMAND"

SOURCE_COMMIT="${GITHUB_REPOSITORY}@${GITHUB_SHA}"
DEFAULT_COMMIT_MSG="Deployed from $SOURCE_COMMIT"

COMMIT_MSG="${INPUT_COMMIT_MSG:-$DEFAULT_COMMIT_MSG}"

cd $GITHUB_WORKSPACE/$CLONE_DIR
# Commit if there is anything to
if [ -n "$(git status --porcelain)" ]; then
    echo "โ๏ธ Committing changes"
    git add .
    git commit -m "$COMMIT_MSG"
    echo "๐ Pushing the changes"
    git push -f origin $TARGET_BRANCH
else
    echo "๐คท๐ปโโ๏ธ No changes to push"
fi

echo "โ All done"
