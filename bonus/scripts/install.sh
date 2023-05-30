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

message "Create namespace gitlab"
kubectl create namespace gitlab
kubectl get ns | grep 'gitlab'
check_exit_code "namespace gitlab"
kubectl apply -f ../controllers/gitlab/gitlab-deployment.yaml -n gitlab
kubectl apply -f ../controllers/gitlab/gitlab-svc.yaml -n gitlab
message "Wait pod to be ready"
kubectl wait -n gitlab --for=condition=ready --timeout=600s pod -l app=gitlab-app
kubectl get all -n gitlab
message "Sleep 60sec to be sure that the gitlab is fully available"
sleep 60
message "Port forward"
k3d cluster edit p3-iot --port-add "7777:30082@loadbalancer"
message "Installation successful you can now connect to the gitlab at: http://127.0.0.1:7777"
message "There is the password of root user of gitlab:"
kubectl exec -it deployment/gitlab-deployment -n gitlab -- grep 'Password:' /etc/gitlab/initial_root_password