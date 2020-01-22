#!/bin/bash

minikube version >/dev/null 2>&1
if [ 0 -ne "$?" ]; then
    echo "Minikube is not installed."
    exit 1
fi

# Gets the status of Minikube
minikube status >/dev/null
if [ 0 -ne "$?" ]; then
    # Start Minikube Virtualbox machine
    minikube start --registry-mirror https://registry.docker-cn.com --logtostderr
fi

# Check if working dir accessible in Virtualbox machine
minikube ssh "df -P $PWD" >/dev/null 2>&1
if [ 0 -ne "$?" ]; then
    if [ ! -z "$VBOX_MSI_INSTALL_PATH" ]; then
        VBOXMANAGE="${VBOX_MSI_INSTALL_PATH}VBoxManage.exe"
    else
        VBOXMANAGE="${VBOX_INSTALL_PATH}VBoxManage.exe"
    fi
    "$VBOXMANAGE" --version >/dev/null 2>&1
    if [ 0 -ne "$?" ]; then
        echo "VirtualBox is not installed."
        exit 1
    fi
    df . --output=source,target | awk 'END { print $1,$2 }' | while read HOST_PATH MOUNT_POINT
    do
        minikube stop
        "$VBOXMANAGE" sharedfolder add minikube --name "${MOUNT_POINT:1}" --hostpath "$HOST_PATH\\" --automount
        minikube start
    done
fi