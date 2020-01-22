#!/bin/bash
mkdir -p ~/.minikube/files/etc/docker/certs.d/<domain>
cp <certificatefile> ~/.minikube/files/etc/docker/certs.d/<domain>/ca.crt
cp <certificatefile> ~/.minikube/files/etc/ssl/certs/<domain>.pem
