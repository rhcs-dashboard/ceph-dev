#!/bin/bash

set -e

readonly PRE_COMMIT_FILE=/ceph/.git/hooks/pre-commit

rm -rf "$PRE_COMMIT_FILE"

echo "#!/bin/bash

set -e

cd $HOST_PWD

docker-compose run --rm ceph /docker/ci/pre-commit.sh
" > "$PRE_COMMIT_FILE"

chmod 755 "$PRE_COMMIT_FILE"

echo 'Pre-commit hook successfully set up!'
