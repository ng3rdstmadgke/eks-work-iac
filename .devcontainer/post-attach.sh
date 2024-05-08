#!/bin/bash

set -ex

SCRIPT_DIR=$(cd $(dirname $0); pwd)

# dockerコンフィグから credsStore を削除する
DOCKER_CONFIG="$HOME/.docker/config.json"
if [ -r "$DOCKER_CONFIG" ] && [ "$(cat $DOCKER_CONFIG | jq '.credsStore')" != "null" ]; then
  cat $DOCKER_CONFIG | jq -r 'del(.credsStore)' | tee $DOCKER_CONFIG
fi
