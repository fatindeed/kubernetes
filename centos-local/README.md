# CentOS 7.2 Kubernetes安装备忘

1.  安装Docker

2.  设置本机时区

    ```sh
    cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
    ```

3.  关闭SWAP

    ```sh
    swapoff -a
    systemctl daemon-reload
    ```

4.  [安装Kubernetes（kubeadm、kubelet、kubectl）](https://kubernetes.io/docs/setup/independent/install-kubeadm/#installing-kubeadm-kubelet-and-kubectl)

    ```sh
    cat <<EOF > /etc/yum.repos.d/kubernetes.repo
    [kubernetes]
    name=Kubernetes
    baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
    enabled=1
    gpgcheck=1
    repo_gpgcheck=1
    gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
    EOF

    # Set SELinux in permissive mode (effectively disabling it)
    setenforce 0
    sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

    yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes

    systemctl enable kubelet && systemctl start kubelet

    cat <<EOF >  /etc/sysctl.d/k8s.conf
    net.bridge.bridge-nf-call-ip6tables = 1
    net.bridge.bridge-nf-call-iptables = 1
    EOF
    sysctl --system
    ```

5.  预更新镜像

    ```sh
    IMAGES=$(kubeadm config images list)
    for IMAGE in ${IMAGES[@]}
    do
        ALIYUN_IMAGE="registry.cn-hangzhou.aliyuncs.com/google_containers/${IMAGE#k8s.gcr.io/}"
        docker pull "$ALIYUN_IMAGE"
        docker tag "$ALIYUN_IMAGE" "$IMAGE"
        docker rmi "$ALIYUN_IMAGE"
    done
    ```

6.  [使用kubeadm初始化集群](https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/)

    ```sh
    kubeadm init --pod-network-cidr=10.244.0.0/16 --kubernetes-version=v1.12.2
    ```
<!-- kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=192.168.38.51 -->

7.  配置kubectl客户端

    如果本机也安装了kubectl，只需[稍作配置](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/)，即可对集群进行管理，非常方便。

    ```sh
    scp user@host:/etc/kubernetes/admin.conf $HOME/.kube/admin.conf
    export KUBECONFIG=$KUBECONFIG:$HOME/.kube/admin.conf
    kubectl config use-context <context-name>
    ```
<!-- kubectl config view --flatten -->

8.  安装pod网络附加组件
    
    **在网络附加组件安装完成之前，KubeDNS/CoreDNS是无法成功启动的。**

    官方提供了[若干可选组件](https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/#pod-network)，这里以安装flannel为例。

    ```sh
    kubectl apply -f kube-flannel.yaml
    ```

    本地的[kube-flannel.yaml](kube-flannel.yaml)修改自官方的[kube-flannel.yml](https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml)，删除了未使用的DaemonSet，仅保留了 `kube-flannel-ds-amd64` 这个DaemonSet。

9.  安装Ingress

    ```sh
    $ kubectl apply -f addons/ingress/
    configmap/nginx-load-balancer-conf created
    configmap/tcp-services created
    configmap/udp-services created
    deployment.extensions/default-http-backend created
    deployment.extensions/nginx-ingress-controller created
    serviceaccount/nginx-ingress created
    clusterrole.rbac.authorization.k8s.io/system:nginx-ingress created
    role.rbac.authorization.k8s.io/system::nginx-ingress-role created
    rolebinding.rbac.authorization.k8s.io/system::nginx-ingress-role-binding created
    clusterrolebinding.rbac.authorization.k8s.io/system:nginx-ingress created
    service/default-http-backend created
    ```

    本地的[addons/ingress](addons/ingress/)修改自Minikube的[addons/ingress](https://github.com/kubernetes/minikube/tree/master/deploy/addons/ingress)，差异见[addons/ingress.diff](addons/ingress.diff)。

    PS: 启动后发现 *nginx-ingress-controller* 状态一直是 **Pending**，使用`kubectl get events -n ingress-nginx`发现如下错误信息

    > Type     Reason            Age                From               Message
    > ----     ------            ----               ----               -------
    > Warning  FailedScheduling  51s (x15 over 3m)  default-scheduler  0/1 nodes are available: 1 node(s) had taints that the pod didn't tolerate.

    意思是 *nginx-ingress-controller* 必须部署在 Node 上，不能部署在 Master 上，运行以下命令即可解决。

    ```sh
    kubectl taint nodes --all node-role.kubernetes.io/master-
    ```

10. 生成证书保密字典

    ```sh
    $ kubectl create secret tls cluster-tls-certificate --cert=path/to/tls.cert --key=path/to/tls.key -n kube-system
    secret/cluster-tls-certificate created
    ```

11. 部署Dashboard

    ```sh
    $ kubectl apply -f addons/dashboard/
    deployment.apps/kubernetes-dashboard created
    service/kubernetes-dashboard created
    ```

    本地的[addons/dashboard](addons/dashboard/)修改自Minikube的[addons/dashboard](https://github.com/kubernetes/minikube/tree/master/deploy/addons/dashboard)，差异见[addons/dashboard.diff](addons/dashboard.diff)。

    配置Dashboard访问：

    ```sh
    $ kubectl apply -f ingress-dashboard.yaml
    ingress.extensions/ingress-dashboard created
    ```

    然后我们就可以通过 https://demo.cluster.eainc.com/dashboard/ 访问Dashboard了。

13. 部署echoserver

    ```sh
    $ kubectl create secret tls cluster-tls-certificate --cert=path/to/tls.cert --key=path/to/tls.key
    secret/cluster-tls-certificate created

    $ (cat <<EOF
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: echoserver
      labels:
        k8s-app: echoserver
    spec:
      replicas: 1
      selector:
        matchLabels:
          k8s-app: echoserver
      template:
        metadata:
          labels:
            k8s-app: echoserver
        spec:
          containers:
          - name: echoserver
            image: registry.cn-hangzhou.aliyuncs.com/google-containers/echoserver:1.4
            ports:
            - containerPort: 8080
    ---
    apiVersion: v1
    kind: Service
    metadata:
      name: echoserver
      labels:
        k8s-app: echoserver
    spec:
      type: NodePort
      selector:
        k8s-app: echoserver
      ports:
      - name: http
        port: 8080
    ---
    apiVersion: extensions/v1beta1
    kind: Ingress
    metadata:
      name: ingress-echoserver
    spec:
      tls:
      - hosts:
        - demo.cluster.eainc.com
        secretName: cluster-tls-certificate
      rules:
      - host: demo.cluster.eainc.com
        http:
          paths:
          - path: /echo
            backend:
              serviceName: echoserver
              servicePort: 8080
    EOF
    ) | kubectl apply -f -
    deployment.apps/echoserver created
    service/echoserver created
    ingress.extensions/ingress-echoserver created
    ```

    点击 https://demo.cluster.eainc.com/echo/ 可以正常显示，就说明配置成功了。当然，也可以使用curl在命令行调试。

    ```sh
    $ curl -ksSL https://demo.cluster.eainc.com/echo/
    CLIENT VALUES:
    client_address=10.244.0.1
    command=GET
    real path=/echo/
    query=nil
    request_version=1.1
    request_uri=http://demo.cluster.eainc.com:8080/echo/

    SERVER VALUES:
    server_version=nginx: 1.10.0 - lua: 10001

    HEADERS RECEIVED:
    accept=*/*
    host=demo.cluster.eainc.com
    user-agent=curl/7.60.0
    x-forwarded-for=172.17.10.147
    x-forwarded-host=demo.cluster.eainc.com
    x-forwarded-port=443
    x-forwarded-proto=https
    x-original-uri=/echo/
    x-real-ip=172.17.10.147
    x-request-id=9761ef886f13a1aa3871bd2b0574da28
    x-scheme=https
    BODY:
    -no body in request-
    ```

14. 部署EFK

    ```sh
    $ kubectl apply -f addons/efk/
    replicationcontroller/elasticsearch-logging created
    service/elasticsearch-logging created
    configmap/fluentd-es-config created
    replicationcontroller/fluentd-es created
    replicationcontroller/kibana-logging created
    service/kibana-logging created
    ```

    本地的[addons/efk](addons/efk/)修改自Minikube的[addons/efk](https://github.com/kubernetes/minikube/tree/master/deploy/addons/efk)，差异见[addons/efk.diff](addons/efk.diff)。

    配置Kibana访问：

    ```sh
    $ kubectl apply -f ingress-kibana.yaml
    ingress.extensions/ingress-kibana created
    ```

    然后我们就可以通过 https://kibana.cluster.eainc.com/ 访问Kibana了。

## 参考页面

- [Installing kubeadm](https://kubernetes.io/docs/setup/independent/install-kubeadm/)
- [Creating a single master cluster with kubeadm](https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/)
- [Configure Access to Multiple Clusters](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/)
- [Organizing Cluster Access Using kubeconfig Files](https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/)
- [flannel](https://github.com/coreos/flannel)
- [NGINX Ingress Controller](https://github.com/kubernetes/ingress-nginx)
- [NGINX Ingress Controller](https://github.com/nginxinc/kubernetes-ingress)
- [Ingress controller examples](https://github.com/kubernetes/contrib/tree/master/ingress/controllers/nginx/examples)
- [Fluentd Daemonset for Kubernetes](https://github.com/fluent/fluentd-kubernetes-daemonset)
- [Kubernetes Dashboard](https://github.com/kubernetes/dashboard)

<!-- https://www.jianshu.com/p/832bcd89bc07 -->