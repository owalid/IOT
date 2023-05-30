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

kubectl create namespace gitlab
kubectl get ns | grep 'gitlab'
check_exit_code "namespace gitlab"
kubectl apply -f ../controllers/gitlab/gitlab-deployment.yaml -n gitlab
kubectl apply -f ../controllers/gitlab/gitlab-svc.yaml -n gitlab
k3d cluster edit p3-iot --port-add "7777:30082@loadbalancer"
