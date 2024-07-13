#!/bin/bash

set -e

REPO_FULLNAME=$(jq -r ".repository.full_name" "$GITHUB_EVENT_PATH")

echo "## Setup git"
git config --global --add safe.directory /github/workspace

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
FILE=./.github/atomicgo/custom_readme
INCLUDE_UNEXPORTED=./.github/atomicgo/include_unexported
if test -f "$FILE"; then
  echo ".github/custom_readme is present. Not generating a new readme."
else
  echo "### Installing Godocdown..."
  go install github.com/robertkrimen/godocdown/godocdown@latest
  echo "### Running Godocdown..."
  $(go env GOPATH)/bin/godocdown -template /template.md >README.md
  echo "### Installing gomarkdoc..."
  go install github.com/princjef/gomarkdoc/cmd/gomarkdoc@latest
  echo "### Running gomarkdoc..."
  GOMARKDOC_FLAGS="--template-file example=/template/example.gotxt"
  if test -f "$INCLUDE_UNEXPORTED"; then
    # add -u flag to include unexported functions
    GOMARKDOC_FLAGS+="-u"
  fi

  $(go env GOPATH)/bin/gomarkdoc $GOMARKDOC_FLAGS --repository.url "https://github.com/$REPO_FULLNAME" --repository.default-branch main --repository.path / -e -o README.md .
fi

echo "# Running CI System"
go get github.com/pterm/pterm
go run /main.go
rm /main.go

echo "## Go mod tidy..."
git checkout go.mod # reset go.mod file
git checkout go.sum # reset go.sum file
go mod tidy

echo "## Staging changes..."
git add .
echo "## Amending the previous commit with updated docs..."
git commit --amend --no-edit || true
echo "## Force pushing to $BRANCH"
git push -f origin "$BRANCH"
