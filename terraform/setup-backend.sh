#!/bin/bash

# Setup Azure Storage for Terraform state management
# Run this before terraform init

set -e

RESOURCE_GROUP="terraform-state-rg"
LOCATION="${1:-eastus}"

echo "🔧 Setting up Terraform state backend in Azure Storage..."
echo ""

# Create Resource Group
echo "📦 Creating Resource Group: $RESOURCE_GROUP"
az group create \
  --name "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --tags Project=terraform ManagedBy=terraform

# Create Dev Storage Account
echo "💾 Creating Storage Account for Dev: tfstatedev"
az storage account create \
  --name tfstatedev \
  --resource-group "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --sku Standard_LRS \
  --kind StorageV2 \
  --tags Environment=dev ManagedBy=terraform

# Create Prod Storage Account
echo "💾 Creating Storage Account for Prod: tfstateprod"
az storage account create \
  --name tfstateprod \
  --resource-group "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --sku Standard_LRS \
  --kind StorageV2 \
  --tags Environment=prod ManagedBy=terraform

# Create containers
echo "📁 Creating storage containers..."
for env in dev prod; do
  account_name="tfstate$env"
  az storage container create \
    --name tfstate \
    --account-name "$account_name" \
    --auth-mode login
  echo "✓ Created container 'tfstate' in $account_name"
done

echo ""
echo "✅ Backend setup complete!"
echo ""
echo "Next steps:"
echo "1. cd terraform/environments/dev"
echo "2. terraform init"
echo "3. cd ../prod"
echo "4. terraform init"
echo ""
