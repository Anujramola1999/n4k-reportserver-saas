# N4K 1.13 + Report Server 0.2 + PostgreSQL Scale Testing

This folder contains all the files needed for large-scale testing of N4K 1.13 with Report Server 0.2 and PostgreSQL backend.

## 📁 File Structure

### 📋 Documentation
- `N4K_1.13_POSTGRESQL_TEST.md` - Comprehensive test guide

### ⚙️ Configuration Files
- `eks-cluster-n4k-1.13.yaml` - EKS cluster configuration
- `postgresql-n4k-1.13-values.yaml` - PostgreSQL Helm values
- `reports-server-0.2-postgresql-values.yaml` - Report Server Helm values
- `kyverno-n4k-1.13-values.yaml` - N4K 1.13 Helm values

### 📊 Monitoring
- `postgresql-servicemonitor.yaml` - PostgreSQL ServiceMonitor
- `postgresql-n4k-1.13-dashboard.json` - Grafana dashboard

### 🛠️ Scripts & Tools
- `generate-large-scale-resources.py` - Resource generation script
- `parallel-apply.sh` - Parallel resource application
- `eks-performance-monitor.sh` - Performance monitoring
- `install-eks-monitoring.sh` - Monitoring stack installation
- `cleanup-eks-cluster.sh` - Cleanup script

## 🚀 Quick Start

1. **Follow the main guide**: `N4K_1.13_POSTGRESQL_TEST.md`
2. **Create EKS cluster**: `eksctl create cluster -f eks-cluster-n4k-1.13.yaml`
3. **Install monitoring**: `./install-eks-monitoring.sh`
4. **Run scale test**: Follow the guide for complete testing

## 📊 Test Scale

- **Namespaces**: 1,425
- **Pods**: 12,000+ (9 pods per namespace)
- **Backend**: PostgreSQL
- **Infrastructure**: EKS (8 m5.2xlarge nodes)

## 💰 Cost Estimation

- **EKS Cluster**: ~$65-110/day
- **Recommended**: Run during off-peak hours and clean up promptly

## 🔧 Prerequisites

- AWS CLI configured
- eksctl installed
- kubectl installed
- helm v3 installed
- python3 installed
- Sufficient AWS credits

## 📈 Performance Targets

- Report generation time: < 1 second average
- PostgreSQL database size: 1-3GB for 12k pods
- Connection pool utilization: < 80%
- No resource exhaustion or OOM kills
