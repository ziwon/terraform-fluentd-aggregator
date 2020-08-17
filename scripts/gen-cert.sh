#! /bin/bash

# Enable debug mode with DEBUG=1
[ -z "$DEBUG" ] || set -x

WORKING_DIR="$( cd "$( dirname "${BASH_SOURCE[1]}" )" >/dev/null 2>&1 && pwd )"
CERT_HOME=$WORKING_DIR/certs

DOMAIN=${DOMAIN:-"docker.local"}
CERT_EXPIRE=${CERT_EXPIRE:-365}

DNS_LIST="${DOMAIN},*.${DOMAIN}"

CA_KEY=./ca/ca-key.pem
CA_CERT=./ca/ca-cert.pem
CA_SUBJECT=$DOMAIN
CA_EXPIRE=$CERT_EXPIRE

SSL_CONFIG=./client/openssl.cnf
SSL_KEY=./client/key.pem
SSL_CSR=./client/key.csr
SSL_CERT=./client/cert.pem
SSL_EXPIRE=$CERT_EXPIRE
SSL_SUBJECT="*.${DOMAIN}"

echo "Generating certs in $CERT_HOME"

mkdir -p "$CERT_HOME/ca"
mkdir -p "$CERT_HOME/client"

rm -rf "$CERT_HOME/ca/**"
rm -rf "$CERT_HOME/client/**"

# Use local docker in order to generate certs
unset DOCKER_HOST

docker run \
    -e CA_KEY="$CA_KEY" \
    -e CA_CERT="$CA_CERT" \
    -e CA_SUBJECT="$CA_SUBJECT" \
    -e CA_EXPIRE="$CA_EXPIRE" \
    -e SSL_CONFIG="$SSL_CONFIG" \
    -e SSL_KEY="$SSL_KEY" \
    -e SSL_CSR="$SSL_CSR" \
    -e SSL_CERT="$SSL_CERT" \
    -e SSL_EXPIRE="$SSL_EXPIRE" \
    -e SSL_SUBJECT="$SSL_SUBJECT" \
    -e SSL_DNS="$DNS_LIST" \
    -v "$CERT_HOME:/certs" \
    paulczar/omgwtfssl
