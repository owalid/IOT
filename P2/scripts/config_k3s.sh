#!/bin/bash

# export DEBIAN_FRONTEND=noninteractive

function check_exit_code
{
    if [ ! $? -eq 0 ]; then
    echo "Installation of "$1" failed. The program will exit."
    exit 1
    else
        echo ""$1" installed, cool !"
    fi
}

echo "Update debian database and Add curl to it."
sudo apt update
sudo apt install curl gpg -y
which curl
if [ ! $? -eq 0 ]; then
    echo "Curl could not be installed"
    exit 1
fi
echo "Installing k3s..."
curl -sfL https://get.k3s.io | sh -
if [ ! -d /home/vagrant/.kube ];then
    echo ".kube directory does not exist. We will create it."
    mkdir /home/vagrant/.kube
fi
if [ ! -f  /home/vagrant/.kube/config ];then
    echo "config file does not exist. We will create it."
    kubectl config view --raw >> /home/vagrant/.kube/config
fi
echo "export KUBECONFIG=/home/vagrant/.kube/config" >> /home/vagrant/.bashrc
source /home/vagrant/.bashrc
sudo k3s kubectl get node
check_exit_code "k3s"
echo "Installing helm package manager for kubernetes"
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm
which helm
check_exit_code "helm"
echo "Generating a certicates for secure http..."
openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -keyout tls.key -out tls.crt -subj "/CN=nginxsvc/O=nginxsvc"
echo "Add secret, key and cert to k3s"
kubectl create secret tls tls-secret --key tls.key --cert tls.crt
echo "Installing nginx ingress-controller as reverse proxy for applications..."
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install --kubeconfig /home/vagrant/.kube/config ingress-nginx-app123 ingress-nginx/ingress-nginx \
--set controller.defaultTLS.cert=tls.crt --set controller.defaultTLS.key=tls.key --set controller.defaultTLS.secret=tls-secret \
--set controller.service.loadBalancerIP=192.168.56.110
helm status ingress-nginx
check_exit_code "ingress-nginx"
wget https://github.com/paulbouwer/hello-kubernetes/archive/refs/tags/v1.10.1.tar.gz
tar -xvzf v1.10.1.tar.gz
cd hello-kubernetes-1.10.1/deploy/helm/
helm install --kubeconfig /home/vagrant/.kube/config --create-namespace --namespace hello-kubernetes ingress-nginx-app123 ./hello-kubernetes \
  --set ingress.configured=true --set ingress.pathPrefix=custom-message \
  --set service.type=ClusterIP \
  --set message="Hello from App3" \
  --set controller.replicaCount=3