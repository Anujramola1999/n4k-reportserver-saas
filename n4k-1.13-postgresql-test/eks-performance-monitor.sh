#!/bin/bash

echo "=== EKS Performance Monitor ==="
echo "Timestamp: $(date)"
echo

# Cluster metrics
echo "=== Cluster Metrics ==="
kubectl top nodes
echo

# Pod counts
echo "=== Pod Counts ==="
TOTAL_PODS=$(kubectl get pods -A --no-headers | wc -l)
TOTAL_NAMESPACES=$(kubectl get namespaces --no-headers | wc -l)
TEST_PODS=$(kubectl get pods -A | grep large-scale-test | wc -l)
TEST_NAMESPACES=$(kubectl get namespaces | grep large-scale-test | wc -l)

echo "Total pods: $TOTAL_PODS"
echo "Total namespaces: $TOTAL_NAMESPACES"
echo "Test pods: $TEST_PODS"
echo "Test namespaces: $TEST_NAMESPACES"
echo

# Kyverno metrics
echo "=== Kyverno Metrics ==="
kubectl top pods -n kyverno
echo

# Report counts
echo "=== Report Counts ==="
POLR_COUNT=$(kubectl get polr -A --no-headers | wc -l)
CPOLR_COUNT=$(kubectl get cpolr --no-headers | wc -l)
echo "PolicyReports: $POLR_COUNT"
echo "ClusterPolicyReports: $CPOLR_COUNT"
echo

# Resource usage
echo "=== Resource Usage ==="
kubectl get pods -n kyverno -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.containerStatuses[0].ready}{"\t"}{.status.phase}{"\n"}{end}'
echo

# PostgreSQL metrics (if using PostgreSQL backend)
if kubectl get pods -n kyverno | grep -q postgresql; then
    echo "=== PostgreSQL Metrics ==="
    kubectl -n kyverno exec postgresql-0 -- psql -U postgres -d reports_server -c "
        SELECT 
            pg_size_pretty(pg_database_size('reports_server')) as db_size,
            (SELECT COUNT(*) FROM policy_reports) as report_count,
            (SELECT COUNT(*) FROM cluster_policy_reports) as cluster_report_count,
            (SELECT count(*) FROM pg_stat_activity WHERE state = 'active') as active_connections;
    " 2>/dev/null || echo "PostgreSQL not ready yet"
    echo
fi

# etcd metrics (if using etcd backend)
if kubectl get pods -n kyverno | grep -q etcd; then
    echo "=== etcd Metrics ==="
    for i in 0 1 2 3 4; do
        if kubectl get pods -n kyverno | grep -q "etcd-$i"; then
            echo "etcd-$i:"
            kubectl -n kyverno exec etcd-$i -c etcd -- etcdctl endpoint status --write-out=table 2>/dev/null || echo "etcd-$i not ready"
        fi
    done
    echo
fi

# Recent events
echo "=== Recent Events ==="
kubectl get events --sort-by='.lastTimestamp' | tail -5
echo
