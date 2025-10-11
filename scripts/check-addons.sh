#!/bin/bash

# Script to check the status of EKS addons
# Usage: ./scripts/check-addons.sh <cluster-name> <region>

set -e

CLUSTER_NAME=${1:-"eventim-devops-dev-cluster"}
REGION=${2:-"us-west-2"}

echo "🔍 Checking addon status for cluster: $CLUSTER_NAME in region: $REGION"

# Check EKS addons
ADDONS=("vpc-cni" "coredns" "kube-proxy" "aws-ebs-csi-driver")

for addon in "${ADDONS[@]}"; do
    echo "📋 Checking addon: $addon"
    
    # Get addon status
    STATUS=$(aws eks describe-addon --cluster-name "$CLUSTER_NAME" --addon-name "$addon" --region "$REGION" --query 'addon.status' --output text 2>/dev/null || echo "NOT_FOUND")
    
    if [ "$STATUS" = "NOT_FOUND" ]; then
        echo "❌ Addon $addon not found"
    elif [ "$STATUS" = "ACTIVE" ]; then
        echo "✅ Addon $addon is ACTIVE"
    elif [ "$STATUS" = "DEGRADED" ]; then
        echo "⚠️  Addon $addon is DEGRADED - checking pods..."
        
        # Check if pods are running
        if kubectl get pods -n kube-system | grep -q "$addon" | grep -q "Running"; then
            echo "✅ $addon pods are running correctly"
            echo "💡 The DEGRADED status is a false positive from AWS"
        else
            echo "❌ $addon pods are not running"
        fi
    else
        echo "🔄 Addon $addon is in status: $STATUS"
    fi
    echo ""
done

echo "🏁 Verification completed"

