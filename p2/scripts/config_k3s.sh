#!/bin/bash

BOLD_RED="\033[1;31m"
BOLD_BLUE="\033[1;34m"
RESET="\033[0m"

function message
{
    echo -e "${BOLD_BLUE}$1${RESET}"
}

function error
{
    echo -e "${BOLD_RED}$1${RESET}"
}

function check_exit_code
{
    if [ ! $? -eq 0 ]; then
        error "Installation of "$1" failed. The program will exit."
        exit 1
    else
        message ""$1" installed, cool !"
    fi
}

function add_ressources
{
    message "Update debian database and add curl and gpg to it."
    sudo apt update
    sudo apt install curl gpg -y
    which curl
    check_exit_code "curl"
    which gpg
    check_exit_code "gpg"
    message "Installing k3s..."
    curl -sfL https://get.k3s.io | sh -s - server --node-ip=192.168.56.110
    if [ ! -d /home/vagrant/.kube ];then
        message ".kube directory does not exist. We will create it."
        mkdir /home/vagrant/.kube
    fi
    if [ ! -f  /home/vagrant/.kube/config ];then
        message "config file does not exist. We will create it."
        kubectl config view --raw >> /home/vagrant/.kube/config
    fi
    echo "export KUBECONFIG=/home/vagrant/.kube/config" >> /home/vagrant/.bashrc
    source /home/vagrant/.bashrc
    chmod 644 /home/vagrant/.kube/config
    sudo k3s kubectl get node
    check_exit_code "k3s"
    message "Installing helm package manager for kubernetes"
    curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
    sudo apt-get install apt-transport-https --yes
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
    sudo apt-get update
    sudo apt-get install helm
    which helm
    check_exit_code "helm"
}

function add_helm_repos
{
    message "Add repos for nginx ingress controller and hello-kubernetes app"
    helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
    helm repo add opsmx https://helmcharts.opsmx.com/
    helm repo update
}

function add_nginx_ingress_controller
{
    message "Installing nginx ingress-controller as reverse proxy for applications..."
    sudo helm install --wait --kubeconfig /home/vagrant/.kube/config ingress-nginx-hello-kubernetes ingress-nginx/ingress-nginx
    helm status ingress-nginx-hello-kubernetes
}

function add_hello_kubernetes
{
    message "Installing "$1" instance of hello kubernetes"
    sudo helm install --wait --kubeconfig /home/vagrant/.kube/config "$1" opsmx/hello-kubernetes --version 1.0.3 \
    --set ingress.configured=true \
    --set ingress.rewritePath=/ \
    --set service.type=ClusterIP \
    --set message="Hello from "$1"" \
    --set deployment.replicaCount=$2
}

function tests
{
    sleep 1
    message "Getting pods"
    kubectl get po -o wide
    sleep 1
    message "Getting services"
    kubectl get svc
    sleep 1
    message "Get everything"
    kubectl get all
    sleep 1
    message "Test with App1"
    curl -H "Host: app1.com" 192.168.56.110
    sleep 1
    message "Test with App2"
    curl -H "Host: app2.com" 192.168.56.110
    sleep 1
    message "Test with App3"
    curl 192.168.56.110
    message "You can know test it on the host machine!"
}

add_ressources
add_helm_repos
add_nginx_ingress_controller
add_hello_kubernetes app1 1
add_hello_kubernetes app2 3
add_hello_kubernetes app3 1
kubectl apply -n default -f /controllers/ingress/ingress_hello-kubernetes.yaml
tests