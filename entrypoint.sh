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
git fetch origin "$BRANCH"
echo "### Branch: $BRANCH (ref: $GITHUB_REF )"
git checkout "$BRANCH"

echo "## Login into git..."
git config --global user.email "git@marvinjwendt.com"
git config --global user.name "MarvinJWendt"

echo "## Ignore workflow files (we may not touch them)"
git update-index --assume-unchanged .github/workflows/*

echo "## Getting git tags..."
git fetch --tags

echo "## Generating readme..."
FILE=./.github/custom_readme
if test -f "$FILE"; then
  echo ".github/custom_readme is present. Not generating a new readme."
else
  go run github.com/robertkrimen/godocdown/godocdown -template /template.md >README.md
fi

echo "# Running CI System"
go run /main.go
rm /main.go

echo "## Generating changelog..."
go run github.com/git-chglog/git-chglog/cmd/git-chglog -o CHANGELOG.md --config /.chglog/config.yml || true

echo "## Go mod tidy..."
git checkout go.mod # reset go.mod file
go mod tidy

echo "## Go fmt..."
go fmt ./...

echo "## Staging changes..."
git add .
echo "## Committing files..."
git commit -m "docs: autoupdate" || true
echo "## Pushing to $BRANCH"
git push -u origin "$BRANCH"
