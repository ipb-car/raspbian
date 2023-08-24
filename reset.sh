#!/usr/bin/env bash

cd "$(dirname "$BASH_SOURCE")"

git submodule deinit -f pi-gen
git submodule update --init
