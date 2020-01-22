#!/bin/bash
# https://letsencrypt.org/docs/certificates-for-localhost/
openssl req -x509 -out localhost.crt -keyout localhost.key \
  -newkey rsa:2048 -nodes -sha256 \
  -subj '/CN=localhost' -extensions EXT -config <( \
   printf "[dn]\nCN=localhost\n[req]\ndistinguished_name = dn\n[EXT]\nsubjectAltName=DNS:localhost\nkeyUsage=digitalSignature\nextendedKeyUsage=serverAuth")
# add the certificate for all users
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain localhost.crt
# add the certificate to your own local keychain only
security add-trusted-cert -d -r trustRoot -k ~/Library/Keychains/login.keychain localhost.crt
