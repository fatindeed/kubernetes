#!/bin/bash
# https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/
# https://www.jianshu.com/p/832bcd89bc07

cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
yum install -y kubelet kubeadm kubectl

swapoff -a
systemctl daemon-reload

IMAGES=$(kubeadm config images list)
for IMAGE in ${IMAGES[@]}
do
    ALIYUN_IMAGE="registry.cn-hangzhou.aliyuncs.com/google_containers/${IMAGE#k8s.gcr.io/}"
    docker pull "$ALIYUN_IMAGE"
    docker tag "$ALIYUN_IMAGE" "$IMAGE"
    docker rmi "$ALIYUN_IMAGE"
done

# kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=192.168.38.51 
kubeadm init --pod-network-cidr=10.244.0.0/16 --kubernetes-version=v1.12.2
# You can now join any number of machines by running the following on each node
# as root:
#   kubeadm join 192.168.38.51:6443 --token txkofy.44vspdzn2g5tzvcm --discovery-token-ca-cert-hash sha256:f6e8d7eebfd3c66127dad0666ae341e4ac5f4f3c5978573b3fdc99ce0454318d
scp root@192.168.38.51:/etc/kubernetes/admin.conf .

sysctl net.bridge.bridge-nf-call-iptables=1
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
# ssl: https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/alternative/kubernetes-dashboard.yaml
# https://www.linuxba.com/archives/8163
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/mandatory.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/provider/baremetal/service-nodeport.yaml

# FailedScheduling | Pod | 0/1 nodes are available: 1 node(s) had taints that the pod didn't tolerate.
kubectl taint nodes --all node-role.kubernetes.io/master-
