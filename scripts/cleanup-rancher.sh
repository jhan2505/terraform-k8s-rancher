#!/bin/bash

# =============================================================================
# Rancher Cleanup Script
# =============================================================================
# This script helps clean up Rancher resources when terraform destroy fails
# due to finalizers or stuck jobs.

set -e

echo "🧹 Starting Rancher cleanup process..."

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed or not in PATH"
    exit 1
fi

# Check if cluster is accessible
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Cannot connect to Kubernetes cluster"
    echo "Please run: aws eks update-kubeconfig --region <region> --name <cluster-name>"
    exit 1
fi

echo "✅ Connected to Kubernetes cluster"

# Function to remove finalizers from a resource
remove_finalizers() {
    local resource_type=$1
    local resource_name=$2
    local namespace=$3
    
    echo "🔧 Removing finalizers from $resource_type/$resource_name in namespace $namespace"
    
    kubectl patch $resource_type $resource_name -n $namespace -p '{"metadata":{"finalizers":[]}}' --type=merge || {
        echo "⚠️  Failed to remove finalizers from $resource_type/$resource_name"
    }
}

# Function to delete jobs in namespace
delete_jobs() {
    local namespace=$1
    echo "🗑️  Deleting all jobs in namespace $namespace"
    
    kubectl get jobs -n $namespace --no-headers -o custom-columns=":metadata.name" | while read job; do
        if [ ! -z "$job" ]; then
            echo "Deleting job: $job"
            kubectl delete job $job -n $namespace --force --grace-period=0 || true
        fi
    done
}

# Function to clean up namespace
cleanup_namespace() {
    local namespace=$1
    echo "🧹 Cleaning up namespace: $namespace"
    
    # Delete all jobs first
    delete_jobs $namespace
    
    # Remove finalizers from all resources in the namespace
    echo "🔧 Removing finalizers from all resources in $namespace"
    
    # Get all resource types in the namespace
    kubectl api-resources --verbs=list --namespaced -o name | while read resource; do
        kubectl get $resource -n $namespace --no-headers -o custom-columns=":metadata.name" 2>/dev/null | while read name; do
            if [ ! -z "$name" ]; then
                remove_finalizers $resource $name $namespace
            fi
        done
    done
    
    # Finally, delete the namespace
    echo "🗑️  Force deleting namespace: $namespace"
    kubectl delete namespace $namespace --force --grace-period=0 || true
}

# Main cleanup process
echo "🚀 Starting cleanup process..."

# Clean up cattle-system namespace
cleanup_namespace "cattle-system"

# Clean up any other Rancher-related namespaces
echo "🔍 Looking for other Rancher-related namespaces..."
kubectl get namespaces --no-headers -o custom-columns=":metadata.name" | grep -E "(cattle|rancher)" | while read ns; do
    if [ ! -z "$ns" ]; then
        echo "Found Rancher namespace: $ns"
        cleanup_namespace $ns
    fi
done

echo "✅ Rancher cleanup completed!"
echo ""
echo "📋 Next steps:"
echo "1. Run 'terraform destroy' again"
echo "2. If it still fails, check for any remaining resources manually"
echo "3. Use 'kubectl get all --all-namespaces' to verify cleanup"




