#!/usr/bin/env bash

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

function install_k3d
{
    message "Installing k3d"
    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
    k3d --version
    check_exit_code k3d
    message "Enable auto-completion for k3d"
    echo "source <(k3d completion bash)" >> ~/.bashrc
    source ~/.bashrc
}

function install_kubectl
{
    message "Installing k3s"
    curl -sfL https://get.k3s.io | sh -s - --no-deploy=servicelb
    if [ ! -d ~/.kube ];then
        message ".kube directory does not exist. We will create it."
        mkdir ~/.kube
    fi
    if [ ! -f ~/.kube/config ];then
        message "config file does not exist. We will create it."
        sudo kubectl config view --raw >> ~/.kube/config
    fi
    echo "export KUBECONFIG=~/.kube/config" >> ~/.bashrc
    source ~/.bashrc
    chmod 600 ~/.kube/config
    kubectl version
    check_exit_code "kubectl"
}

function create_cluster_and_namespaces
{
    message "Creating cluster and the namespace dev and argo"
    k3d cluster create p3-iot --api-port 6443 -p 8080:80@loadbalancerZ
    kubectl cluster-info
    kubectl create namespace argocd
    kubectl create namespace dev
    kubectl get ns | grep 'argocd'
    check_exit_code "namespace argocd"
    kubectl get ns | grep 'dev'
    check_exit_code "namespace dev"
}

function install_and_configure_argo_cd
{
    message "Installing argocd server to the cluster"
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    message "Installing argo-cli"
    curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
    sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
    rm argocd-linux-amd64
    message "Set argocd-server service as load balancer in order to access to the api"
    kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
    message "The api server should be available at https://localhost:8080"
    message "Setting env variable to allow cli to connect to api server"
    export ARGOCD_OPTS='--port-forward-namespace argocd'
    echo "export ARGOCD_OPTS='--port-forward-namespace argocd'" >> ~/.bashrc
    source ~/.bashrc
    message "Getting the autogenerated admin password for argo cd"
    argocd admin initial-password -n argocd
    argocd login localhost:8080
}

function add_wil_app_to_argocd
{
    message "Create an app with argo cd."
    kubectl config set-context --current --namespace=argocd
    argocd app create wil-app --repo https://github.com/kibatche/oel-ayad-chbadad-iot-p3.git --path . --dest-server https://kubernetes.default.svc --dest-namespace dev
    message "Add automated sync policy to wil-app"
    argocd app set wil-app --sync-policy automated
    message "Syncing app"
    argocd app sync wil-app
    message "Checking the status of the app"
    argocd app get wil-app
}

install_k3d
install_kubectl
create_cluster_and_namespaces
install_and_configure_argo_cd
add_wil_app_to_argocd
