#!/bin/bash

# Exit on any error
set -e

# Install K3s
install_k3s() {
    echo "Installing K3s..."
    curl -sfL https://get.k3s.io | sh -
    echo "K3s installed successfully."

    # Export KUBECONFIG for kubectl to interact with the K3s cluster
    export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
    echo "KUBECONFIG set to /etc/rancher/k3s/k3s.yaml"

    # Verify installation
    kubectl get nodes
}

# Install Helm
install_helm() {
    echo "Installing Helm..."
    curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    echo "Helm installed successfully."

    # Verify installation
    helm version
}

# Install Jenkins via Helm chart
install_jenkins() {
    echo "Adding Jenkins Helm repo..."
    helm repo add jenkinsci https://charts.jenkins.io
    helm repo update

    echo "Creating jenkins namespace..."
    kubectl create namespace jenkins || true

    echo "Installing Jenkins..."
    helm install jenkins jenkinsci/jenkins --namespace jenkins --set controller.serviceType=LoadBalancer

    echo "Jenkins installation initiated. Waiting for Jenkins pods to be ready..."
    kubectl wait --namespace jenkins --for=condition=ready pod -l app.kubernetes.io/instance=jenkins --timeout=300s

    echo "Jenkins installed successfully."

    # Retrieve Jenkins admin password
    echo "Fetching Jenkins admin password..."
    kubectl get secret --namespace jenkins jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode
    echo
}

# Main script
main() {
    install_k3s
    install_helm
    install_jenkins

    echo "K3s, Helm, and Jenkins installation complete."
    echo "Jenkins is accessible via the LoadBalancer IP on port 8080."
    echo "Use the password above to log in to the Jenkins UI."
}

main
