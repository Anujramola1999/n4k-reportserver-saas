# Kyverno Report Server Scale Test with etcd Backend

## 1. Purpose

This guide describes how to run the Kyverno Report Server scale test with an etcd backend.
It covers cluster setup, monitoring installation, Kyverno + Report Server deployment, data generation, metrics collection, and validation.
It is designed to be reproducible, beginner-friendly, and aligned with the Kyverno Report Server – Scale Testing & Benchmark Plan.

---

## 2. Test Environment Setup

### 2.1 Prerequisites

You will need the following tools installed locally:
- **kind** – Local Kubernetes cluster tool
- **kubectl** – Kubernetes CLI
- **helm** – Kubernetes package manager
- **jq / yq** – For JSON/YAML parsing in shell scripts

```bash
brew install kind kubectl helm jq yq
```

### 2.2 Create Test Cluster

We use KIND for local functional tests.

```bash
kind delete cluster --name kyverno-reports-test || true
kind create cluster --config kind-config.yaml --wait 600s
kubectl get nodes -o wide
```

**Why it matters:**
- A fresh cluster ensures no leftover resources.
- Waiting for readiness avoids flaky test failures.

---

## 3. Install Monitoring Stack

We'll install Prometheus + Grafana to capture performance metrics.

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  -n monitoring --create-namespace \
  --set grafana.enabled=true \
  --set grafana.service.type=NodePort --set grafana.service.nodePort=30001 \
  --set prometheus.service.type=NodePort --set prometheus.service.nodePort=30000

# Retrieve Grafana password
kubectl -n monitoring get secret monitoring-grafana -o jsonpath='{.data.admin-password}' | base64 -d; echo
```

**Why it matters:**
- Prometheus scrapes metrics from Kyverno and Report Server.
- Grafana visualizes them for easier analysis.
- NodePorts let you access dashboards from your host.

---

## 4. Install Report Server (etcd backend)

```bash
helm repo add rs https://nirmata.github.io/reports-server/
helm repo update
helm upgrade --install reports-server rs/reports-server \
  -n kyverno --create-namespace --version 0.2.3
```

**Why before Kyverno?**
Kyverno detects if Report Server CRDs exist — installing it first ensures reports are offloaded from control-plane etcd immediately.

---

## 5. Install Kyverno (N4K 1.14)

```bash
helm repo add nirmata https://nirmata.github.io/kyverno-charts/
helm repo update
helm upgrade --install kyverno nirmata/kyverno \
  -n kyverno --create-namespace --version 3.4.7
kubectl -n kyverno get pods
```

**Why it matters:**
- Matches our test plan version matrix.
- Ensures Kyverno is running with external reporting.

---

## 6. Enable Metrics Scraping

```bash
kubectl apply -f reports-server-servicemonitor.yaml
kubectl apply -f kyverno-servicemonitor.yaml
kubectl apply -f reports-server-etcd-servicemonitor.yaml
```

**Why it matters:**
- Prometheus needs ServiceMonitors to discover metrics endpoints.
- Without them, dashboards will remain empty.

---

## 7. Deploy Baseline Policies

```bash
test -d kyverno-policies || git clone --depth 1 https://github.com/nirmata/kyverno-policies.git
kubectl kustomize kyverno-policies/pod-security/baseline | kubectl apply -f -
```

**Why it matters:**
- Policies generate violations → these create report data.
- Needed to measure report generation performance.

---

## 8. Generate Load

Example: Create 100 namespaces and violating pods

```bash
for i in $(seq 1 100); do kubectl create ns lt-$i; done
for i in $(seq 1 100); do kubectl -n lt-$i apply -f baseline-violations-pod.yaml; done
```

**Why it matters:**
- Large data volume stresses Report Server and etcd.
- Allows us to measure report generation latency.

---

## 9. Open Dashboards

- **Prometheus**: http://localhost:30000
- **Grafana**: http://localhost:30001
- Import `kyverno-dashboard.json` for visualizing metrics.

---

## 10. Measure etcd Sizes

```bash
ETCD_POD=$(kubectl -n kube-system get pods -l component=etcd -o jsonpath='{.items[0].metadata.name}')
kubectl -n kube-system exec $ETCD_POD -- etcdctl endpoint status --write-out=table

for i in 0 1 2; do
  kubectl -n kyverno exec etcd-$i -c etcd -- etcdctl endpoint status --write-out=table
done
```

**Why it matters:**
- Confirms offload — control-plane etcd should grow slower than RS etcd.

---

## 11. Validation Signals

- `kubectl get polr -A` shows both pass & fail results.
- Grafana panels show non-zero report counts and latencies.
- RS etcd size grows in line with load.

---

## 12. Cleanup

```bash
kind delete cluster --name kyverno-reports-test
```
