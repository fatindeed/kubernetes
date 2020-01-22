#!/bin/bash
# https://yq.aliyun.com/articles/221687
minikube version
minikube start --registry-mirror https://registry.docker-cn.com --logtostderr
# minikube logs | grep k8s.gcr.io > minikube.log
kubectl config get-contexts
kubectl version
kubectl cluster-info
kubectl get nodes
minikube ssh "docker images"
minikube ssh "$HOME/pull-k8s.sh"
# minikube addons enable dashboard
minikube dashboard --url

minikube addons list
minikube addons disable dashboard
kubectl get pod,svc -n kube-system
kubectl get svc kubernetes-dashboard -n kube-system
kubectl get deployments -n kube-system
kubectl get services -n kube-system
kubectl expose deployment kubernetes-dashboard --port=80 --target-port=30000 -n kube-system

kubectl get pods --all-namespaces
kubectl get pods -n kube-system
kubectl get pods --context=minikube

kubectl run hello-minikube --image=registry.cn-hangzhou.aliyuncs.com/google_containers/echoserver:1.10 --port=8080
kubectl expose deployment hello-minikube --type=NodePort
curl -sSL $(minikube service hello-minikube --url)
kubectl delete services hello-minikube
kubectl delete deployment hello-minikube
minikube stop
