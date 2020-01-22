#!/bin/bash
# https://kubernetes.io/docs/tutorials/hello-minikube/
# https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands
# https://github.com/feiskyer/kubernetes-handbook
# https://www.jianshu.com/p/832bcd89bc07
# https://www.kubernetes.org.cn/
kubectl version
kubectl config get-contexts
kubectl cluster-info
kubectl get nodes
kubectl cluster-info dump --namespaces kube-system | grep k8s.gcr.io
kubectl cluster-info dump --namespaces kube-system | grep "Error response from daemon: Get https://k8s.gcr.io/v2/"
kubectl cluster-info dump | grep "Error response from daemon: Get https://k8s.gcr.io/v2/"
kubectl get pod,events --all-namespaces
kubectl describe pod --all-namespaces

kubectl get events -w
kubectl get pod,deployment,service,ingress
kubectl get pod,deploy,svc,ing,event
kubectl describe ingress
# https://kubernetes.io/docs/tasks/access-application-cluster/port-forward-access-application-cluster/


# Create a Deployment
kubectl run hello-node --image=gcr.io/hello-minikube-zero-install/hello-node --port=8080
kubectl get deployments
kubectl get pods
kubectl get events
kubectl config view

# Create a Service
kubectl expose deployment hello-node --type=LoadBalancer
kubectl get services
minikube service hello-node
minikube service list

# Clean up
kubectl delete service hello-node
kubectl delete deployment hello-node

kubectl create -f kubernetes-dashboard.yaml
kubectl proxy
# http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/#!/overview?namespace=default


