#!/bin/sh

# Create dummy self-signed certs
mkdir -p /dummycert
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /dummycert/privkey.pem \
  -out /dummycert/fullchain.pem \
  -subj "/CN=localhost"