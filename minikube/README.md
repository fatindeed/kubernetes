# Minikube安装备忘

1.  安装Minikube

    根据[官方文档](https://kubernetes.io/docs/tasks/tools/install-minikube/)安装Minikube。唯一需要注意的是，[官方版本](https://github.com/kubernetes/minikube/releases)会因为k8s.gcr.io被墙的问题，无法正常使用，推荐使用[阿里云修改版](https://github.com/AliyunContainerService/minikube/releases)。

2.  首次启动Minikube建议加上`--registry-mirror https://registry.docker-cn.com`参数，使用Docker中国镜像。

    ```sh
    minikube start --registry-mirror https://registry.docker-cn.com
    ```

3.  添加共享文件夹

    和**Docker Toolbox**一样，默认的共享目录只有`C:\Users`，要使用其它目录的话，请参考[start.sh](start.sh)脚本。

4.  启用Ingress

    ```sh
    $ minikube addons enable ingress
    ingress was successfully enabled
    ```

5.  生成证书保密字典

    ```sh
    $ kubectl create secret tls minikube-tls-certificate --cert=path/to/tls.cert --key=path/to/tls.key -n kube-system
    secret/minikube-tls-certificate created
    ```

6.  通过Ingress访问Dashboard

    ```sh
    $ minikube addons enable dashboard
    dashboard was successfully enabled

    $ (cat <<EOF
    apiVersion: extensions/v1beta1
    kind: Ingress
    metadata:
     name: ingress-dashboard
     namespace: kube-system
    spec:
     tls:
     - hosts:
       - dashboard.minikube.local
       secretName: minikube-tls-certificate
     rules:
     - host: dashboard.minikube.local
       http:
         paths:
         - backend:
             serviceName: kubernetes-dashboard
             servicePort: 80
    EOF
    ) | kubectl apply -f -
    ingress.extensions/ingress-dashboard created
    ```

    然后我们就可以通过 https://dashboard.minikube.local/ 访问Dashboard了。

7.  部署echoserver

    ```sh
    $ kubectl create secret tls minikube-tls-certificate --cert=path/to/tls.cert --key=path/to/tls.key
    secret/minikube-tls-certificate created

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
        - echoserver.minikube.local
        secretName: minikube-tls-certificate
      rules:
      - host: echoserver.minikube.local
        http:
          paths:
          - backend:
              serviceName: echoserver
              servicePort: 8080
    EOF
    ) | kubectl apply -f -
    deployment.apps/echoserver created
    service/echoserver created
    ingress.extensions/ingress-echoserver created
    ```

    点击 https://echoserver.minikube.local/ 可以正常显示，就说明配置成功了。当然，也可以使用curl在命令行调试。

    ```sh
    $ curl -ksSL https://echoserver.minikube.local
    CLIENT VALUES:
    client_address=172.17.0.6
    command=GET
    real path=/
    query=nil
    request_version=1.1
    request_uri=http://echoserver.minikube.local:8080/

    SERVER VALUES:
    server_version=nginx: 1.10.0 - lua: 10001

    HEADERS RECEIVED:
    accept=*/*
    connection=close
    host=echoserver.minikube.local
    user-agent=curl/7.60.0
    x-forwarded-for=192.168.99.1
    x-forwarded-host=echoserver.minikube.local
    x-forwarded-port=443
    x-forwarded-proto=https
    x-original-uri=/
    x-real-ip=192.168.99.1
    x-request-id=67aa87581a56681768abb4e88265f434
    x-scheme=https
    BODY:
    -no body in request-
    ```

8.  拉取私人仓库

    如果是`http`的私人仓库，只需在初始化的时候加上`--insecure-registry`参数。

    ```sh
    minikube start --registry-mirror https://registry.docker-cn.com --insecure-registry <domain>
    ```

    如果是`https`的私人仓库，那么在需要拉取的时候先将CA证书传到服务器上，再进行拉取。

    ```sh
    cat <certificatefile> | minikube ssh "sudo mkdir -p /etc/docker/certs.d/<docker-server> && sudo tee /etc/docker/certs.d/<docker-server>/ca.crt"
    ```

    记得需要在YAML文件中加上`imagePullPolicy: IfNotPresent`，因为重启后CA证书就消失了，仍然会无法连接。

    如果私人仓库需要身份验证，可以通过`kubectl`创建`docker-registry`类型的`secret`

    ```sh
    
    $ kubectl create secret docker-registry --dry-run=true docker-registry-key --docker-server=<domain> --docker-username=<username> --docker-password=<password> --docker-email=<email> -o yaml
    apiVersion: v1
    data:
      .dockerconfigjson: <secret>
    kind: Secret
    metadata:
      creationTimestamp: null
      name: docker-registry-key
    type: kubernetes.io/dockerconfigjson
    ```

9.  启用EFK

    ```sh
    $ minikube addons enable efk
    efk was successfully enabled
    ```

    如果`elasticsearch-logging`在启动时出现如下错误，关闭minikube虚拟机后，手动调整CPU和内存大小即可。建议调整为`cpus: 4, memory: 8192`

    > 0/1 nodes are available: 1 Insufficient memory

    ```sh
    $ (cat <<EOF
    apiVersion: extensions/v1beta1
    kind: Ingress
    metadata:
      name: ingress-kibana
      namespace: kube-system
    spec:
      tls:
      - hosts:
        - kibana.minikube.local
        secretName: minikube-tls-certificate
      rules:
      - host: kibana.minikube.local
        http:
          paths:
          - backend:
              serviceName: kibana-logging
              servicePort: 5601
    EOF
    ) | kubectl apply -f -
    ingress.extensions/ingress-kibana created
    ```

    然后我们就可以通过 https://kibana.minikube.local/ 访问Kibana了。

## 参考页面

- [Install Minikube](https://kubernetes.io/docs/tasks/tools/install-minikube/)
- [Running Kubernetes Locally via Minikube](https://kubernetes.io/docs/setup/minikube/)
- [Github: Minikube](https://github.com/kubernetes/minikube)
- [Github: Minikube edited by Aliyun](https://github.com/AliyunContainerService/minikube)
- [阿里云容器镜像服务](https://dev.aliyun.com/search.html)