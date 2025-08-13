#!/bin/bash
set -e

# Configuration
TOTAL_NAMESPACES=1425
PODS_PER_NAMESPACE=9
BATCH_SIZE=50
MAX_PARALLEL_JOBS=10

echo "=== Parallel Resource Application ==="

# Function to apply resources with retry
apply_with_retry() {
    local file=$1
    local max_retries=3
    local retry_count=0
    
    while [ $retry_count -lt $max_retries ]; do
        if kubectl apply -f "$file" --server-side --force-conflicts; then
            return 0
        else
            retry_count=$((retry_count + 1))
            echo "Retry $retry_count for $file"
            sleep 5
        fi
    done
    
    echo "Failed to apply $file after $max_retries retries"
    return 1
}

# Apply namespaces first
echo "Applying namespaces..."
apply_with_retry "large-scale-resources/namespaces.yaml"

# Wait for namespaces to be ready
echo "Waiting for namespaces to be ready..."
kubectl wait --for=condition=active namespace --selector=test=large-scale --timeout=300s

# Apply pods in parallel batches
echo "Applying pods in parallel batches..."

# Count total batch files
BATCH_FILES=$(ls large-scale-resources/pods-batch-*.yaml | wc -l)

for ((i=1; i<=BATCH_FILES; i++)); do
    # Check how many jobs are running
    while [ $(jobs -r | wc -l) -ge $MAX_PARALLEL_JOBS ]; do
        sleep 2
    done
    
    # Start background job
    (
        echo "Applying batch $i..."
        apply_with_retry "large-scale-resources/pods-batch-$i.yaml"
        echo "Completed batch $i"
    ) &
    
    # Small delay between job starts
    sleep 1
done

# Wait for all background jobs to complete
echo "Waiting for all batches to complete..."
wait

echo "=== Resource Application Completed ==="
