#!/usr/bin/env bash

BOLD_RED="\033[1;31m"
BOLD_BLUE="\033[1;34m"
RESET="\033[0m"
ARGOCD_OPTS="--port-forward-namespace argocd --insecure --plaintext"
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
}

function install_kubectl
{
    message "Installing kubectl"
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    curl -LO "https://dl.k8s.io/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
    echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    kubectl version --client
    check_exit_code "kubectl"
}

function create_cluster_and_namespaces
{
    message "Creating cluster and the namespace dev and argo"
    k3d cluster create p3-iot -p "8080:80@loadbalancer" -p "8888:30080@agent:0" --agents 2
    kubectl cluster-info
    kubectl create namespace argocd && kubectl create namespace dev
    kubectl get ns | grep 'argocd'
    check_exit_code "namespace argocd"
    kubectl get ns | grep 'dev'
    check_exit_code "namespace dev"
}

function install_and_configure_argo_cd
{
    message "Installing argocd server to the cluster"
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    message "Installing params options for argocd"
    kubectl apply -n argocd -f ../controllers/argocd/argocd-cmd-params/argocd-cmd-params.yaml
    message "Update argocd-server to make change available"
    kubectl -n argocd rollout restart deployment argocd-server
    message "Waiting for restart to be complete..."
    kubectl -n argocd rollout status deployment argocd-server
    message "Installing ingress for argocd"
    kubectl apply -n argocd -f ../controllers/argocd/argocd-ingress/argocd-ingress.yaml
    message "Installing argo-cli"
    curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
    sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
    rm argocd-linux-amd64
    message "Set argocd-server service as load balancer in order to access to the api"
    message "The api server should be available at https://localhost:8080"
    message "Setting env variable to allow cli to connect to api server"
    grep -xq "export ARGOCD_OPTS='--port-forward-namespace argocd --insecure --plaintext'" /home/taskmasters/.bashrc
    if [ ! $? -eq 0 ];then
        echo "export ARGOCD_OPTS='--port-forward-namespace argocd --insecure --plaintext'" >> /home/taskmasters/.bashrc
        source /home/taskmasters/.bashrc
    fi
    message "Getting the autogenerated admin password for argo cd"
    argocd admin initial-password -n argocd --port-forward-namespace argocd --insecure --plaintext
    while [ ! $? -eq 0 ]
    do
        message "Waiting for argocd server to be available..."
        sleep 1
        argocd admin initial-password -n argocd --port-forward-namespace argocd --insecure --plaintext
    done
    message "Login to the admin account. To let argocd to be fully available we will wait 10 seconds... Sorry for that."
    sleep 10
    argocd login argocd.local:8080 --port-forward-namespace argocd --insecure --plaintext
    message "Change the password of the admin account"
    argocd account update-password --port-forward-namespace argocd --insecure --plaintext
}

function add_wil_app_to_argocd
{
    message "Create an app with argo cd."
    argocd app create wil-app --repo https://github.com/kibatche/oel-ayad-chbadad-iot-p3.git --path . --dest-server https://kubernetes.default.svc --dest-namespace dev --port-forward-namespace argocd --insecure --plaintext
    message "Add automated sync policy to wil-app"
    argocd app set wil-app --sync-policy automated --port-forward-namespace argocd --insecure --plaintext
    message "Syncing app"
    argocd app sync wil-app --port-forward-namespace argocd --insecure --plaintext
    message "Checking the status of the app"
    argocd app wait wil-app --port-forward-namespace argocd --insecure --plaintext
}

function test_ci_cd_flow
{
    message "Test with v1"
    curl localhost:8888
    message "Git clone and push v2"
    cd /home/taskmasters
    git clone git@github.com:kibatche/oel-ayad-chbadad-iot-p3.git
    cd oel-ayad-chbadad-iot-p3
    sed -i 's/wil42\/playground\:v1/wil42\/playground\:v2/g' wil-app-deployment.yaml
    git add .
    git commit -m "Change to the v2"
    git push origin main
    message "Syncing the app"
    argocd app sync wil-app --port-forward-namespace argocd --insecure --plaintext
    argocd app wait wil-app --port-forward-namespace argocd --insecure --plaintext
    message "Test with v2"
    curl localhost:8888
    sed -i 's/wil42\/playground\:v2/wil42\/playground\:v1/g' wil-app-deployment.yaml
    git add .
    git commit -m "Change to the v1"
    git push origin main
}

install_kubectl
install_k3d
create_cluster_and_namespaces
install_and_configure_argo_cd
add_wil_app_to_argocd
test_ci_cd_flow
rm -rf /home/taskmasters/oel-ayad-chbadad-iot-p3
