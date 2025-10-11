#!/bin/bash

# Script to fix addons in DEGRADED state
# Usage: ./scripts/fix-degraded-addons.sh <cluster-name> <region>

set -e

CLUSTER_NAME=${1:-"eventim-devops-dev-cluster"}
REGION=${2:-"us-west-2"}

echo "🔧 Fixing addons in DEGRADED state for cluster: $CLUSTER_NAME"

# List of addons that can be in DEGRADED state
ADDONS=("coredns" "aws-ebs-csi-driver")

for addon in "${ADDONS[@]}"; do
    echo "📋 Checking addon: $addon"
    
    # Get addon status
    STATUS=$(aws eks describe-addon --cluster-name "$CLUSTER_NAME" --addon-name "$addon" --region "$REGION" --query 'addon.status' --output text 2>/dev/null || echo "NOT_FOUND")
    
    if [ "$STATUS" = "DEGRADED" ]; then
        echo "⚠️  Addon $addon is DEGRADED - attempting to fix..."
        
        # Check if pods are running
        if kubectl get pods -n kube-system | grep -q "$addon" | grep -q "Running"; then
            echo "✅ Pods are running, forcing addon update..."
            
            # Force addon update
            aws eks update-addon \
                --cluster-name "$CLUSTER_NAME" \
                --addon-name "$addon" \
                --resolve-conflicts OVERWRITE \
                --region "$REGION" \
                --no-wait
            
            echo "🔄 Update initiated for $addon"
        else
            echo "❌ Pods are not running, cannot fix automatically"
        fi
    elif [ "$STATUS" = "ACTIVE" ]; then
        echo "✅ Addon $addon is already ACTIVE"
    else
        echo "ℹ️  Addon $addon is in status: $STATUS"
    fi
    echo ""
done

echo "🏁 Fix completed"
echo "💡 If addons are still in DEGRADED state, run 'terraform refresh' to sync the state"

