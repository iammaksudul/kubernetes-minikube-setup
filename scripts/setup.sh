#!/bin/bash

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO] $1${NC}"; }
warn() { echo -e "${YELLOW}[WARN] $1${NC}"; }
error() { echo -e "${RED}[ERROR] $1${NC}"; exit 1; }

check_dependencies() {
    log "Checking dependencies..."
    
    if ! command -v minikube &> /dev/null; then
        error "Minikube not found. Install from https://minikube.sigs.k8s.io/"
    fi
    
    if ! command -v kubectl &> /dev/null; then
        error "kubectl not found. Install from https://kubernetes.io/docs/tasks/tools/"
    fi
    
    log "Dependencies check passed"
}

start_minikube() {
    log "Starting Minikube cluster..."
    
    minikube start \
        --driver=docker \
        --cpus=2 \
        --memory=4096 \
        --disk-size=20g \
        --kubernetes-version=v1.28.0
    
    log "Minikube cluster started successfully"
}

enable_addons() {
    log "Enabling Minikube addons..."
    
    minikube addons enable ingress
    minikube addons enable dashboard
    minikube addons enable metrics-server
    
    log "Addons enabled successfully"
}

deploy_application() {
    log "Deploying application..."
    
    kubectl apply -f manifests/app-deployment.yaml
    kubectl apply -f manifests/configmap.yaml
    kubectl apply -f manifests/secret.yaml
    
    log "Application deployed successfully"
}

wait_for_pods() {
    log "Waiting for pods to be ready..."
    
    kubectl wait --for=condition=ready pod -l app=devops-app --timeout=300s
    
    log "All pods are ready"
}

show_status() {
    log "Cluster Status:"
    kubectl get nodes
    echo ""
    
    log "Application Status:"
    kubectl get pods,svc,ingress
    echo ""
    
    log "Access URLs:"
    echo "Dashboard: $(minikube dashboard --url)"
    echo "Application: http://$(minikube ip)"
}

main() {
    log "Setting up Kubernetes development environment..."
    
    check_dependencies
    start_minikube
    enable_addons
    deploy_application
    wait_for_pods
    show_status
    
    log "Setup completed successfully!"
}

case "${1:-setup}" in
    "setup") main ;;
    "start") minikube start ;;
    "stop") minikube stop ;;
    "delete") minikube delete ;;
    "status") show_status ;;
    *) echo "Usage: $0 {setup|start|stop|delete|status}"; exit 1 ;;
esac
