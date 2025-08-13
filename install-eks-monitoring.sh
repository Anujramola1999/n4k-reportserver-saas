#!/bin/bash
set -e

echo "=== Installing Monitoring Stack on EKS ==="

# Add Helm repos
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Install monitoring stack
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  -n monitoring --create-namespace \
  --set grafana.enabled=true \
  --set grafana.service.type=LoadBalancer \
  --set grafana.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-type"=nlb \
  --set grafana.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-nlb-target-type"=ip \
  --set grafana.persistence.enabled=true \
  --set grafana.persistence.size=20Gi \
  --set grafana.persistence.storageClassName=gp3 \
  --set prometheus.prometheusSpec.retention=7d \
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.accessModes[0]=ReadWriteOnce \
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage=100Gi \
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.storageClassName=gp3 \
  --set prometheus.prometheusSpec.resources.requests.memory=2Gi \
  --set prometheus.prometheusSpec.resources.requests.cpu=1 \
  --set prometheus.prometheusSpec.resources.limits.memory=8Gi \
  --set prometheus.prometheusSpec.resources.limits.cpu=4 \
  --set nodeExporter.enabled=true \
  --set kubeStateMetrics.enabled=true \
  --set kubeStateMetrics.resources.requests.memory=256Mi \
  --set kubeStateMetrics.resources.requests.cpu=100m \
  --set kubeStateMetrics.resources.limits.memory=1Gi \
  --set kubeStateMetrics.resources.limits.cpu=500m \
  --wait --timeout=15m

# Get Grafana admin password
echo "Grafana admin password:"
kubectl -n monitoring get secret monitoring-grafana -o jsonpath='{.data.admin-password}' | base64 -d
echo

# Get LoadBalancer URL
echo "Grafana URL:"
kubectl -n monitoring get svc monitoring-grafana -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
echo

# Install additional ServiceMonitors
kubectl apply -f reports-server-servicemonitor.yaml
kubectl apply -f kyverno-servicemonitor.yaml
kubectl apply -f postgresql-servicemonitor.yaml

echo "=== Monitoring Stack Installed ==="
