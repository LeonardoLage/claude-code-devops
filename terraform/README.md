# Terraform - Azure Container Apps Infrastructure

Infraestrutura como código para provisionar a aplicação `kube-news` na Azure usando Container Apps com suporte para múltiplos ambientes (Dev e Prod).

## Estrutura

```
terraform/
├── main.tf                          # Provider e Resource Group
├── variables.tf                     # Definição de variáveis
├── outputs.tf                       # Outputs
├── networking.tf                    # VNet, subnets, DNS
├── keyvault.tf                      # Azure Key Vault
├── registry.tf                      # Azure Container Registry
├── database.tf                      # PostgreSQL Flexible Server
├── container_apps.tf                # Container Apps + App Insights
├── .gitignore                       # Git ignore rules
├── environments/
│   ├── dev/
│   │   ├── terraform.tfvars        # Dev environment variables
│   │   ├── backend.tf              # Dev state backend (local)
│   │   └── terraform-dev.tfstate   # Local state file (git ignored)
│   └── prod/
│       ├── terraform.tfvars        # Prod environment variables
│       ├── backend.tf              # Prod state backend (Azure Storage)
│       └── terraform.tfstate       # State (managed remotely)
└── README.md                        # Este arquivo
```

## Arquitetura

```
┌─ Azure Resource Group ─────────────────────────────────────────┐
│ (kube-news-dev-rg ou kube-news-prod-rg)                        │
│                                                                  │
│  ├─ Virtual Network (10.0.0.0/16)                              │
│  │  ├─ Container Apps Subnet (10.0.1.0/24)                     │
│  │  ├─ Database Subnet (10.0.2.0/24)                           │
│  │  └─ Private DNS Zone (postgres.database.azure.com)          │
│  │                                                               │
│  ├─ Container Apps Environment                                  │
│  │  └─ Container App (kube-news-dev-app / kube-news-prod-app)  │
│  │     ├─ Image: leonardorlage/kube-news:v1.0                  │
│  │     ├─ Port: 8080                                            │
│  │     ├─ Probes: Liveness + Readiness                          │
│  │     └─ HTTPS via Container Apps Ingress                     │
│  │                                                               │
│  ├─ PostgreSQL Flexible Server                                  │
│  │  ├─ Dev: B_Standard_B1ms, 32GB, 7 dias backup               │
│  │  └─ Prod: B_Standard_B2s, 64GB, 30 dias backup              │
│  │                                                               │
│  ├─ Azure Container Registry (Basic - Free tier)                │
│  │                                                               │
│  ├─ Key Vault (Standard)                                        │
│  │  └─ Secrets: db-username, db-password, db-connection-string │
│  │                                                               │
│  └─ Observabilidade                                             │
│     ├─ Log Analytics Workspace (5GB/mês)                        │
│     └─ Application Insights                                     │
└────────────────────────────────────────────────────────────────┘
```

## Pré-requisitos

1. **Azure CLI**: `az --version`
2. **Terraform**: `terraform --version` (>= 1.0)
3. **Conta Azure** com subscrição ativa
4. **Credenciais Azure**:
   ```bash
   az login
   az account set --subscription <SUBSCRIPTION_ID>
   ```

## Setup Inicial

### 1. Estrutura de diretórios

A estrutura já está criada em `terraform/environments/{dev,prod}/`

### 2. Configurar variáveis

#### Dev:
```bash
# Editar terraform/environments/dev/terraform.tfvars
# Mudar db_admin_password para algo seguro
```

#### Prod:
```bash
# Editar terraform/environments/prod/terraform.tfvars
# OBRIGATÓRIO: Usar senhas forte e segura!
```

### 3. Inicializar Terraform

#### Dev:
```bash
cd terraform/environments/dev
terraform init
```

#### Prod:
```bash
cd terraform/environments/prod
# Para usar Azure Storage como backend:
terraform init -backend-config=backend.tf
```

## Deployment

### Estrutura de comandos

Todos os comandos devem ser executados dentro do diretório do ambiente:

```bash
cd terraform/environments/dev  # ou prod
```

### Plan (dry-run)

```bash
terraform plan -var-file=terraform.tfvars -out=tfplan
```

### Apply (criar recursos)

```bash
terraform apply tfplan
```

### Outputs

```bash
terraform output
terraform output container_app_url
terraform output postgres_fqdn
```

### Destroy (deletar recursos)

```bash
terraform destroy -var-file=terraform.tfvars
```

## Diferenças Dev vs Prod

| Aspecto | Dev | Prod |
|---|---|---|
| **Location** | eastus | eastus |
| **App Replicas** | 1 | 2 |
| **App CPU** | 0.25 | 0.5 |
| **App Memory** | 0.5Gi | 1Gi |
| **DB SKU** | B_Standard_B1ms | B_Standard_B2s |
| **DB Storage** | 32GB | 64GB |
| **Backup Retention** | 7 dias | 30 dias |
| **Geo-Redundancy** | Não | Sim |
| **Log Retention** | 30 dias | 90 dias |
| **Public Endpoint** | Não | Não |

## Secrets Management

### Senhas no Key Vault

Todas as senhas são armazenadas no Azure Key Vault:

```bash
# Ver secrets armazenados
az keyvault secret list --vault-name <VAULT_NAME>

# Recuperar um secret
az keyvault secret show --vault-name <VAULT_NAME> --name db-password
```

### Arquivo terraform.tfvars

Contém valores sensíveis e está em `.gitignore` — **NUNCA commitar!**

Para compartilhar:
1. Usar Azure Key Vault ou Secrets Manager
2. Ou passar via variáveis de ambiente:
   ```bash
   export TF_VAR_db_admin_password="sua_senha"
   ```

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Terraform Apply

on:
  push:
    branches: [main]
    paths:
      - 'terraform/**'

env:
  ARM_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
  ARM_CLIENT_SECRET: ${{ secrets.AZURE_CLIENT_SECRET }}
  ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
  ARM_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}

jobs:
  terraform:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: hashicorp/setup-terraform@v2
      - run: |
          cd terraform/environments/prod
          terraform init
          terraform plan -var-file=terraform.tfvars
          terraform apply -auto-approve tfplan
```

## Troubleshooting

### Erro: "Invalid authentication credentials"

```bash
az login
az account set --subscription <SUBSCRIPTION_ID>
```

### Erro: "Resource already exists"

Mudar nome do projeto ou ambiente em `terraform.tfvars`

### Erro: "Private endpoint DNS resolution failed"

Aguardar 5-10 minutos para DNS propagar

### Ver logs da aplicação

```bash
# Dev
az containerapp logs show -n kube-news-dev-app -g kube-news-dev-rg

# Prod
az containerapp logs show -n kube-news-prod-app -g kube-news-prod-rg
```

### Atualizar imagem do container

```bash
terraform apply -var='container_image=leonardorlage/kube-news:v2.0'
```

## State Management

### Local State (Dev)

- Arquivo: `terraform-dev.tfstate`
- Bom para desenvolvimento local
- Git ignored

### Azure Storage (Prod)

Recomendado para produção:

```bash
# Criar Storage Account
az group create -n terraform-state-rg -l eastus
az storage account create -n tfstateprod -g terraform-state-rg -l eastus --sku Standard_LRS
az storage container create -n tfstate --account-name tfstateprod
```

Então usar backend em `environments/prod/backend.tf`

## Monitoramento

### Application Insights

Acessar via portal Azure:
- Resource Group: `kube-news-{dev,prod}-rg`
- Application Insights: `kube-news-{dev,prod}-ai`

### Log Analytics

Queries úteis:

```kusto
// Últimos 100 logs da app
ContainerAppConsoleLogs
| order by TimeGenerated desc
| limit 100

// Erros dos últimos 24h
ContainerAppConsoleLogs
| where TimeGenerated > ago(24h)
| where Log has "ERROR" or Log has "Exception"
```

## Custos

### Free Tier (12 meses)
- Container Apps: Primeiras 2M requests/mês
- PostgreSQL: B_Standard_B1ms
- Container Registry: Basic

### Após 12 meses

Dev (~$50/mês):
- Container App: ~$10
- PostgreSQL B1ms: ~$30
- Registry Basic: ~$5
- Log Analytics: ~$5

Prod (~$150/mês):
- 2x Container Apps: ~$20
- PostgreSQL B2s: ~$100
- Registry Basic: ~$5
- Log Analytics: ~$20
- Geo-redundancy: ~$5

## Referências

- [Azure Container Apps Docs](https://learn.microsoft.com/en-us/azure/container-apps/)
- [PostgreSQL Flexible Server](https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Container Apps Pricing](https://azure.microsoft.com/en-us/pricing/details/container-apps/)
