#!/bin/bash

set -e

ENVIRONMENT=${1:-dev}
ACTION=${2:-plan}

TF_DIR="environments/$ENVIRONMENT"
TF_VARS="$TF_DIR/terraform.tfvars"

if [ ! -d "$TF_DIR" ]; then
    echo "✗ Environment not found: $ENVIRONMENT"
    echo "Available environments: dev, prod"
    exit 1
fi

if [ ! -f "$TF_VARS" ]; then
    echo "✗ terraform.tfvars not found: $TF_VARS"
    exit 1
fi

cd "$TF_DIR"

case $ACTION in
    init)
        echo "🔧 Initializing Terraform for $ENVIRONMENT environment..."
        terraform init
        echo "✓ Terraform initialized"
        ;;

    plan)
        echo "📋 Planning infrastructure for $ENVIRONMENT environment..."
        terraform plan -var-file=$(basename "$TF_VARS") -out=tfplan
        echo "✓ Plan created"
        ;;

    apply)
        echo "🚀 Applying infrastructure for $ENVIRONMENT environment..."
        if [ ! -f "tfplan" ]; then
            echo "⚠️  tfplan not found. Running plan first..."
            terraform plan -var-file=$(basename "$TF_VARS") -out=tfplan
        fi
        terraform apply tfplan
        echo "✓ Infrastructure deployed"
        echo ""
        terraform output
        ;;

    destroy)
        echo "⚠️  WARNING: Destroying infrastructure in $ENVIRONMENT environment!"
        echo "This action cannot be undone."
        read -p "Type '$ENVIRONMENT' to confirm: " confirm
        if [ "$confirm" = "$ENVIRONMENT" ]; then
            terraform destroy -var-file=$(basename "$TF_VARS") -auto-approve
            echo "✓ Infrastructure destroyed"
        else
            echo "✗ Destroy cancelled"
            exit 1
        fi
        ;;

    output)
        echo "📊 Outputs for $ENVIRONMENT environment:"
        terraform output
        ;;

    *)
        echo "Usage: ./deploy.sh [dev|prod] [init|plan|apply|destroy|output]"
        echo ""
        echo "Examples:"
        echo "  ./deploy.sh dev plan"
        echo "  ./deploy.sh dev apply"
        echo "  ./deploy.sh prod plan"
        echo "  ./deploy.sh prod apply"
        exit 1
        ;;
esac
