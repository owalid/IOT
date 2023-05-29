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

kubectl create namespace dev
kubectl get ns | grep 'argocd'
check_exit_code "namespace argocd"

curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

helm repo add gitlab https://charts.gitlab.io/
helm repo update
helm upgrade --install gitlab-app gitlab/gitlab \
    -n gitlab \
    --timeout 600s \
    --set global.hosts.domain=example.com \
    --set global.hosts.externalIP=10.10.10.10 \
    --set certmanager-issuer.email=me@example.com \
    --set postgresql.image.tag=13.6.0

kubectl get secret gitlab-app-gitlab-initial-root-password -ojsonpath='{.data.password}' | base64 --decode ; echo