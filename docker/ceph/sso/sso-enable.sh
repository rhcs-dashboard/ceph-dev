#!/bin/bash

set -e

cd /ceph/build

"$CEPH_BIN"/ceph dashboard sso setup saml2 \
    https://localhost:11000 \
    /docker/sso/idp-metadata.xml \
    username \
    http://localhost:8080/auth/realms/saml-demo \
    /docker/sso/saml-certificate.txt \
    /docker/sso/saml-private-key.txt
