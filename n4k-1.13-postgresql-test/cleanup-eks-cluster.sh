#!/bin/bash
set -e

echo "=== Cleaning up EKS Cluster ==="

# Delete test resources
echo "Deleting test namespaces..."
kubectl get namespaces | grep large-scale-test | awk '{print $1}' | xargs -r kubectl delete namespace

# Delete Kyverno and Report Server
echo "Deleting Kyverno and Report Server..."
helm uninstall kyverno -n kyverno || true
helm uninstall reports-server -n kyverno || true

# Delete PostgreSQL
echo "Deleting PostgreSQL..."
helm uninstall postgresql -n kyverno || true

# Delete monitoring
echo "Deleting monitoring stack..."
helm uninstall monitoring -n monitoring || true

# Delete generated resource files
echo "Cleaning up generated files..."
rm -rf large-scale-resources/

# Delete EKS cluster
echo "Deleting EKS cluster..."
eksctl delete cluster --name kyverno-reports-n4k-1.13-test --region us-west-2

echo "=== Cleanup Completed ==="
