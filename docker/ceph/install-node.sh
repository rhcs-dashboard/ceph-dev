#!/bin/bash

set -eo pipefail

curl -LsS https://raw.githubusercontent.com/ceph/ceph/"${VCS_BRANCH}"/make-dist -o /root/make-dist

readonly NODE_VENV_PATH=/opt/node-venv
readonly NODE_VERSION=$(sed -nE 's/^.*nodeenv[^0-9]+([0-9.]+)$/\1/p' /root/make-dist)
nodeenv "${NODE_VENV_PATH}" -n "${NODE_VERSION}" --force

ln -s "${NODE_VENV_PATH}"/bin/node /usr/local/bin/node
ln -s "${NODE_VENV_PATH}"/bin/npm /usr/local/bin/npm
ln -s "${NODE_VENV_PATH}"/bin/npx /usr/local/bin/npx
