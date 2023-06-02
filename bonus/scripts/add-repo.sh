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


function check_empty_var
{
    if [ -z "$2" ]
    then
        error "$1 is empty"
        error "Usage ./add-repo.sh <GITLAB_USER> <GITLAB_REPO_NAME> <ARGOCD_APP_NAME>"
        exit 1
    fi
}


CLUSTER_IP=$(kubectl get service/gitlab-service -n gitlab -o go-template='{{(.spec.clusterIPs)}}' | tr -d '[]')
GITLAB_USER=$1
GITLAB_REPO_NAME=$2
ARGOCD_APP_NAME=$3
GITLAB_END_URL="$GITLAB_USER/$GITLAB_REPO_NAME.git"
check_empty_var $CLUSTER_IP "CLUSTER_IP"
check_empty_var $GITLAB_USER "Gitlab user"
check_empty_var $GITLAB_REPO_NAME "Gitlab repository name"
check_empty_var $ARGOCD_APP_NAME "Name of argocd application to add"

message "Login to argocd"
argocd login argocd.local:8080 --port-forward-namespace argocd --insecure --plaintext

message "Add repository http://$CLUSTER_IP/$GITLAB_END_URL with application name: $ARGOCD_APP_NAME in argocd"
argocd app create $ARGOCD_APP_NAME --repo http://$CLUSTER_IP/$GITLAB_END_URL --path . --dest-server https://kubernetes.default.svc --dest-namespace dev --sync-policy automated --insecure --plaintext

message "Sync $ARGOCD_APP_NAME application name in argocd"
argocd app sync $ARGOCD_APP_NAME --port-forward-namespace argocd --insecure --plaintext
