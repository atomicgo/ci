#!/bin/bash

set -e

REPO_FULLNAME=$(jq -r ".repository.full_name" "$GITHUB_EVENT_PATH")

echo "## Initializing git repo..."
git init
echo "### Adding git remote..."
git remote add origin https://x-access-token:$ACCESS_TOKEN@github.com/$REPO_FULLNAME.git
echo "### Getting branch"
BRANCH=${GITHUB_REF#*refs/heads/}

if [[ $BRANCH == refs/tags* ]]; then
  echo "## The push was a tag, aborting!"
  exit
fi

echo "### git fetch $BRANCH ..."
git fetch origin $BRANCH
echo "### Branch: $BRANCH (ref: $GITHUB_REF )"
git checkout $BRANCH

echo "## Login into git..."
git config --global user.email "git@marvinjwendt.com"
git config --global user.name "MarvinJWendt"

echo "## Ignore workflow files (we may not touch them)"
git update-index --assume-unchanged .github/workflows/*

echo "## Getting git tags..."
git fetch --tags

echo "## Downloading go modules..."
go run github.com/robertkrimen/godocdown -template /template.md

echo "# Running CI System"
go run github.com/atomicgo/ci

echo "## Generating changelog..."
go run github.com/git-chglog/git-chglog/cmd/git-chglog -o CHANGELOG.md

echo "## Go mod tidy..."
go mod tidy

echo "## Go fmt..."
go fmt ./...

echo "## Staging changes..."
git add .
echo "## Commiting files..."
git commit -m "docs: autoupdate" || true
echo "## Pushing to $BRANCH"
git push -u origin $BRANCH