FROM alpine

ENV ISO_VERSION v0.34.1

RUN set -e; \
    apk add --no-cache wget; \
    wget "https://storage.googleapis.com/minikube/iso/minikube-$ISO_VERSION.iso";
