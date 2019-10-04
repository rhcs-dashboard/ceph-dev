#!/usr/bin/env bash

set -eo pipefail

readonly AWS_DIR=/root/.aws
mkdir "$AWS_DIR"
chmod 500 "$AWS_DIR"

echo "[default]" > "$AWS_DIR"/config
chmod 600 "$AWS_DIR"/config

echo "[default]" > "$AWS_DIR"/credentials
chmod 600 "$AWS_DIR"/credentials

echo "alias aws='aws --endpoint-url=http://localhost:8000'" >> /root/.bashrc
