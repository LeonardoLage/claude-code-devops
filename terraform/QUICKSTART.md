# Quick Start Guide - Terraform Deployment

## 📋 Estrutura

```
terraform/
├── *.tf files                           # Código Terraform compartilhado
├── Makefile                             # Comandos para Deploy
├── deploy.sh                            # Script de Deploy
├── setup-backend.sh                     # Setup Storage para State
├── environments/
│   ├── dev/
│   │   ├── terraform.tfvars            # Variáveis Dev
│   │   └── backend.tf                  # State no Azure Storage
│   └── prod/
│       ├── terraform.tfvars            # Variáveis Prod
│       └── backend.tf                  # State no Azure Storage
└── README.md                            # Documentação completa
```

## 🚀 Deploy Rápido

### 1️⃣ Login na Azure

```bash
az login
az account set --subscription <SUBSCRIPTION_ID>
```

### 2️⃣ Setup Storage para State (executar uma vez)

```bash
cd terraform
./setup-backend.sh eastus
```

Isso cria Storage Accounts para armazenar o state (Terraform state files).

### 3️⃣ Editar variáveis

```bash
# Dev (usar para testes)
vim terraform/environments/dev/terraform.tfvars

# Prod (usar para produção)
vim terraform/environments/prod/terraform.tfvars
```

**⚠️ Importante**: Mudar `db_admin_password` em ambos os arquivos!

### 4️⃣ Deploy Dev

```bash
cd terraform

# Opção 1: Usar Makefile
make init ENVIRONMENT=dev
make plan ENVIRONMENT=dev
make apply ENVIRONMENT=dev

# Opção 2: Usar script
./deploy.sh dev init
./deploy.sh dev plan
./deploy.sh dev apply
```

### 5️⃣ Acessar aplicação

```bash
# Ver outputs
make outputs ENVIRONMENT=dev

# Ou
./deploy.sh dev output
```

Acessar em: `https://<container_app_fqdn>`

## 🔄 Deploy Prod (quando pronto)

```bash
# Mesma sequência, mas com ENVIRONMENT=prod
make init ENVIRONMENT=prod
make plan ENVIRONMENT=prod
make apply ENVIRONMENT=prod

# Ou
./deploy.sh prod init
./deploy.sh prod plan
./deploy.sh prod apply
```

## 📊 Scaling com KEDA

App usa **KEDA HTTP scaling** (Kubernetes Event Driven Auto-scaling):

### Dev
- Min Replicas: **0** (scale down quando ocioso, sem custo)
- Max Replicas: **1**
- Trigger: 100 requisições HTTP concorrentes por replica

### Prod
- Min Replicas: **1** (sempre online)
- Max Replicas: **2**
- Trigger: 100 requisições HTTP concorrentes por replica

Exemplo: Se tiver 150 requisições, Prod escalará para 2 replicas.

## 📊 Variáveis Principais

### Dev
- Min Replicas: 0 (KEDA)
- Max Replicas: 1 (KEDA)
- CPU: 0.25 cores
- Memory: 0.5Gi
- DB: B_Standard_B1ms (free tier)
- Backup: ❌ Desabilitado
- Geo-redundancy: ❌ Não

### Prod
- Min Replicas: 1 (KEDA)
- Max Replicas: 2 (KEDA)
- CPU: 0.5 cores
- Memory: 1Gi
- DB: B_Standard_B2s
- Backup: ✅ 30 dias
- Geo-redundancy: ❌ Não

## 🛑 Destruir Infraestrutura

```bash
# Dev
make destroy ENVIRONMENT=dev

# Prod
make destroy ENVIRONMENT=prod

# Ou script
./deploy.sh dev destroy
./deploy.sh prod destroy
```

## 📝 Comandos Úteis

```bash
# Validar configuração
make validate

# Formatar código
make fmt

# Ver estado atual
cd environments/dev && terraform state list

# Ver estado de um recurso
cd environments/dev && terraform state show azurerm_container_app.main

# Destruir apenas um recurso
cd environments/dev && terraform destroy -target=azurerm_container_app.main
```

## 🔑 Secrets & Credenciais

### Acessar Secrets via Azure CLI

```bash
# Dev
az keyvault secret list --vault-name kubenewsdev<SUBSCRIPTION_PREFIX>

az keyvault secret show \
  --vault-name kubenewsdev<SUBSCRIPTION_PREFIX> \
  --name db-password

# Prod
az keyvault secret show \
  --vault-name kubenewsprod<SUBSCRIPTION_PREFIX> \
  --name db-connection-string
```

### Variáveis de Ambiente (Alternative)

```bash
export TF_VAR_db_admin_password="SenhaForte@2026"
export TF_VAR_db_admin_username="kubeadmin"

# Então rodar Terraform normalmente
terraform plan -var-file=environments/dev/terraform.tfvars
```

## 📊 Monitoramento

### Logs da aplicação

```bash
# Dev
az containerapp logs show -n kube-news-dev-app -g kube-news-dev-rg

# Prod
az containerapp logs show -n kube-news-prod-app -g kube-news-prod-rg
```

### Application Insights

Portal Azure → Resource Group → Application Insights → `kube-news-{env}-ai`

### Log Analytics

```bash
# Query útil
az monitor log-analytics query \
  --workspace <WORKSPACE_ID> \
  --analytics-query "ContainerAppConsoleLogs | limit 100"
```

## 🐛 Troubleshooting

### Erro: "Resource already exists"

Mudar nome do projeto em `terraform.tfvars` ou deletar e recriar.

### Erro: "Authentication failed"

```bash
az logout
az login
```

### Erro: "Private endpoint DNS not resolving"

Aguardar 5-10 minutos para DNS propagar.

### Ver plano detalhado antes de aplicar

```bash
cd terraform/environments/dev
terraform plan -var-file=terraform.tfvars -out=tfplan
terraform show tfplan
```

## 📚 Próximos Passos

1. ✅ Deploy Dev (verificar funcionamento)
2. ✅ Testar aplicação em Dev
3. ✅ Deploy Prod (quando tudo OK)
4. ✅ Configurar CI/CD (GitHub Actions, Azure DevOps)
5. ✅ Setup alertas (Application Insights)

## 📖 Mais Informações

Veja `README.md` para:
- Arquitetura completa
- Variáveis detalhadas
- CI/CD integration
- Cost estimation
- State management

---

**Pronto?** Execute:

```bash
cd terraform
./deploy.sh dev plan
```
