# 🔄 GitHub Actions CI/CD

Este diretório contém os workflows do GitHub Actions para CI/CD do Nexo Platform.

## 📋 Arquivos de Workflow

```
.github/workflows/
├── _ci-reusable.yml     # Workflow CI reutilizável
├── _cd-reusable.yml     # Workflow CD reutilizável
├── ci-main.yml          # Orquestrador CI principal
└── cd-main.yml          # Orquestrador CD principal
```

## 🔧 Workflows Reutilizáveis

### `_ci-reusable.yml` - Pipeline CI

Workflow reutilizável que executa:

- ✅ **Lint** - Verificação de qualidade de código
- 🧪 **Test** - Testes unitários e E2E
- 🐳 **Build** - Build Docker e push para GHCR
- 🔒 **Security** - Scan de vulnerabilidades com Trivy

**Entradas:**
| Parâmetro | Descrição | Obrigatório |
|-----------|-----------|-------------|
| service_name | Nome do serviço | ✅ |
| service_path | Caminho do serviço | ✅ |
| build_type | node/maven/docker-only | ❌ |

**Saídas:**
| Saída | Descrição |
|-------|-----------|
| image_tag | Tag da imagem Docker |
| image_digest | Digest da imagem |

---

### `_cd-reusable.yml` - Pipeline CD

Workflow reutilizável que executa:

- ✅ **Validate** - Helm lint e template
- 🔐 **Approval** - Gate manual (staging/prod)
- 🚀 **Deploy** - Sync ArgoCD
- ✅ **Verify** - Health check

**Entradas:**
| Parâmetro | Descrição | Obrigatório |
|-----------|-----------|-------------|
| service_name | Nome do serviço | ✅ |
| environment | dev/qa/staging/prod | ✅ |
| image_tag | Tag da imagem | ✅ |
| auto_sync | Auto-sync ArgoCD | ❌ |

---

## 🎯 Orquestradores

### `ci-main.yml` - CI Principal

Detecta mudanças e dispara CI apenas para serviços alterados.

**Trigger:**

- Push em `main`, `develop`, `qa`, `staging`
- Pull requests

**Serviços monitorados:**

- `apps/nexo-be/**` → nexo-be
- `apps/nexo-fe/**` → nexo-fe
- `apps/nexo-auth/**` → nexo-auth

---

### `cd-main.yml` - CD Principal

Orquestra deploy para todos os ambientes.

**Trigger:**

- Após CI bem-sucedido
- Manual via `workflow_dispatch`

**Ambientes:**
| Ambiente | Branch | Auto-Deploy |
|----------|--------|-------------|
| DEV | develop | ✅ |
| QA | qa | ✅ |
| STAGING | staging | ❌ (aprovação) |
| PROD | main | ❌ (aprovação) |

---

## 🐳 Estratégia de Imagens

### Tags

| Tag           | Descrição      |
| ------------- | -------------- |
| `sha-{short}` | Commit SHA     |
| `develop`     | Última develop |
| `qa`          | Última QA      |
| `staging`     | Última staging |
| `v{semver}`   | Versão release |
| `latest`      | Última main    |

### Registry

```
ghcr.io/geraldobl58/nexo/
├── nexo-be:{tag}
├── nexo-fe:{tag}
└── nexo-auth:{tag}
```

---

## 🔐 Secrets Necessários

Configure os seguintes secrets em **Settings → Secrets and variables → Actions**:

### Repository Secrets

| Secret                   | Descrição                                    | Obrigatório   |
| ------------------------ | -------------------------------------------- | ------------- |
| `GHCR_TOKEN`             | Token para push no GitHub Container Registry | ✅            |
| `KUBECONFIG_DEV`         | Kubeconfig (base64) para cluster DEV         | ✅            |
| `KUBECONFIG_QA`          | Kubeconfig (base64) para cluster QA          | Para QA       |
| `KUBECONFIG_STAGING`     | Kubeconfig (base64) para cluster STAGING     | Para Staging  |
| `KUBECONFIG_PROD`        | Kubeconfig (base64) para cluster PROD        | Para Produção |
| `ARGOCD_AUTH_TOKEN`      | Token de autenticação do ArgoCD              | ✅            |
| `DATABASE_URL_DEV`       | String de conexão PostgreSQL (DEV)           | ✅            |
| `KEYCLOAK_CLIENT_SECRET` | Secret do client Keycloak                    | ✅            |

### Gerar Kubeconfig

```bash
# Para Kind (local)
cat ~/.kube/config | base64 | pbcopy

# Para EKS
aws eks update-kubeconfig --name <cluster> --region <region>
cat ~/.kube/config | base64 | pbcopy

# Para GKE
gcloud container clusters get-credentials <cluster> --zone <zone>
cat ~/.kube/config | base64 | pbcopy
```

### Gerar Token ArgoCD

```bash
# Criar token via CLI
argocd account generate-token --account github-actions

# Ou via UI
# ArgoCD → Settings → Accounts → github-actions → Generate Token
```

---

## 📊 Fluxo de Promoção

```
DEV (auto) ──▶ QA (auto) ──▶ STAGING (aprovação) ──▶ PROD (aprovação)
    │              │               │                     │
    ▼              ▼               ▼                     ▼
 develop          qa           staging                 main
```

### Comandos de Promoção

```bash
# Promover para QA
git checkout qa && git merge develop && git push

# Promover para Staging (cria PR)
gh pr create --base staging --head qa --title "Promote to Staging"

# Promover para Produção (cria PR)
gh pr create --base main --head staging --title "Release vX.Y.Z"
```

---

## 🆘 Troubleshooting

| Problema             | Solução                       |
| -------------------- | ----------------------------- |
| Build falha          | Verificar logs do workflow    |
| Push de imagem falha | Verificar secret `GHCR_TOKEN` |
| Sync ArgoCD falha    | Verificar health da aplicação |

### Comandos Úteis

```bash
# Ver runs do workflow
gh run list

# Ver run específico
gh run view {run_id}

# Re-executar job com falha
gh run rerun {run_id}
```

---

## 📚 Documentação Relacionada

- [Deploy Guide](../../documentation/deploy.md) - Configuração completa de CI/CD
- [Git Branching Strategy](../../documentation/git-branching-strategy.md) - Fluxo de branches
- [Kubernetes](../../documentation/kubernetes.md) - Infraestrutura K8s
- [Arquitetura](../../documentation/architecture.md) - Visão geral da arquitetura
