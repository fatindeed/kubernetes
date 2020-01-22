#!/bin/bash
# https://github.com/AliyunContainerService/k8s-for-docker-desktop
IMAGES=( \
    'pause-amd64:3.1' \
    'kube-controller-manager-amd64:v1.10.3' \
    'kube-scheduler-amd64:v1.10.3' \
    'kube-proxy-amd64:v1.10.3' \
    'kube-apiserver-amd64:v1.10.3' \
    'etcd-amd64:3.1.12' \
    'kube-addon-manager:v8.6' \
    'k8s-dns-sidecar-amd64:1.14.8' \
    'k8s-dns-kube-dns-amd64:1.14.8' \
    'k8s-dns-dnsmasq-nanny-amd64:1.14.8' \
    'kubernetes-dashboard-amd64:v1.8.3' \
    'storage-provisioner:v1.8.1' \
)
for IMAGE in ${IMAGES[@]}
do
    docker pull "registry.cn-hangzhou.aliyuncs.com/google_containers/$IMAGE"
    docker tag "registry.cn-hangzhou.aliyuncs.com/google_containers/$IMAGE" "k8s.gcr.io/$IMAGE"
    docker rmi "registry.cn-hangzhou.aliyuncs.com/google_containers/$IMAGE"
done

# use kubeadm
IMAGES=$(kubeadm config images list)
for IMAGE in ${IMAGES[@]}
do
    NAME="${IMAGE#k8s.gcr.io/}"
    docker pull "registry.cn-hangzhou.aliyuncs.com/google_containers/$NAME"
    docker tag "registry.cn-hangzhou.aliyuncs.com/google_containers/$NAME" "$IMAGE"
    docker rmi "registry.cn-hangzhou.aliyuncs.com/google_containers/$NAME"
done
