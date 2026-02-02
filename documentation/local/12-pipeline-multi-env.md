# Pipeline CI/CD - Fluxo de Deploy Multi-Ambiente

Este documento descreve o fluxo completo de CI/CD da plataforma Nexo, incluindo todos os ambientes e serviços.

---

## 🌿 Ambientes

| Branch    | Ambiente    | Namespace    | URL Base              |
| --------- | ----------- | ------------ | --------------------- |
| `develop` | Development | nexo-develop | \*.develop.nexo.local |
| `qa`      | QA          | nexo-qa      | \*.qa.nexo.local      |
| `staging` | Staging     | nexo-staging | \*.staging.nexo.local |
| `main`    | Production  | nexo-prod    | \*.prod.nexo.local    |

---

## 🔄 Fluxo de Promoção

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   develop   │────▶│     qa      │────▶│   staging   │────▶│    main     │
│             │     │             │     │             │     │   (prod)    │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
       │                  │                   │                   │
       ▼                  ▼                   ▼                   ▼
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│ nexo-develop│     │  nexo-qa    │     │ nexo-staging│     │  nexo-prod  │
│  namespace  │     │  namespace  │     │  namespace  │     │  namespace  │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
```

---

## 📦 Serviços

| Serviço     | Descrição               | Porta |
| ----------- | ----------------------- | ----- |
| `nexo-be`   | Backend NestJS (API)    | 3333  |
| `nexo-fe`   | Frontend Next.js        | 3000  |
| `nexo-auth` | Keycloak (Autenticação) | 8080  |

---

## 🚀 Como Funciona o Pipeline

### Push para develop

1. **Detecta mudanças** nos arquivos de cada serviço
2. **CI**: Lint, Test, Build apenas dos serviços alterados
3. **Docker Build**: Push para GHCR com tag `develop-<sha>`
4. **Deploy**: Atualiza `values-dev.yaml` com nova tag
5. **ArgoCD**: Sincroniza automaticamente

### Merge para qa/staging/main

1. **Detecta merge commit**
2. **Force build**: Todos os serviços são buildados
3. **Docker Build**: Push para GHCR com tag `<branch>-<sha>`
4. **Deploy**: Atualiza `values-<env>.yaml` com nova tag
5. **ArgoCD**: Sincroniza automaticamente

---

## 🛠️ Comandos de Promoção

### Via Makefile (Recomendado)

```bash
# Promover develop para qa
make promote-qa

# Promover qa para staging
make promote-staging

# Promover staging para produção
make promote-prod
```

### Via Script Direto

```bash
./scripts/promote.sh develop qa
./scripts/promote.sh qa staging
./scripts/promote.sh staging main
```

### Via Git Manual

```bash
# Promover develop → qa
git checkout qa
git merge develop
git push origin qa

# Promover qa → staging
git checkout staging
git merge qa
git push origin staging

# Promover staging → main (prod)
git checkout main
git merge staging
git push origin main
```

---

## 🏷️ Estratégia de Tags

Cada imagem recebe duas tags:

1. `<branch>` - Tag móvel (sempre aponta para o último build)
2. `<branch>-<commit-sha>` - Tag imutável (específica do commit)

Exemplo:

```
ghcr.io/geraldobl58/nexo-be:develop
ghcr.io/geraldobl58/nexo-be:develop-abc1234...
```

---

## 📊 Diagrama de Pipeline

```
┌──────────────────────────────────────────────────────────────────────┐
│                         GitHub Actions                                │
├──────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌─────────────┐    ┌──────────────┐    ┌──────────────┐             │
│  │  Pre-flight │───▶│   Detect     │───▶│   CI Jobs    │             │
│  │   Checks    │    │   Changes    │    │ (per-service)│             │
│  └─────────────┘    └──────────────┘    └──────────────┘             │
│                                                │                      │
│                                                ▼                      │
│                           ┌─────────────────────────────────┐        │
│                           │         Build & Push            │        │
│                           │     (nexo-be, nexo-fe, nexo-auth)│        │
│                           └─────────────────────────────────┘        │
│                                                │                      │
│                                                ▼                      │
│                           ┌─────────────────────────────────┐        │
│                           │      Deploy (Update Values)     │        │
│                           └─────────────────────────────────┘        │
│                                                                       │
└───────────────────────────────────┬──────────────────────────────────┘
                                    │
                                    │ Git commit + push
                                    ▼
┌──────────────────────────────────────────────────────────────────────┐
│                              ArgoCD                                   │
├──────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌─────────────┐    ┌──────────────┐    ┌──────────────┐             │
│  │   Detect    │───▶│    Sync      │───▶│   Deploy to  │             │
│  │   Changes   │    │  Helm Chart  │    │     K8s      │             │
│  └─────────────┘    └──────────────┘    └──────────────┘             │
│                                                                       │
└──────────────────────────────────────────────────────────────────────┘
```

---

## 📁 Estrutura de Arquivos

```
local/
├── argocd/
│   ├── apps/
│   │   ├── nexo-develop.yaml    # Apps ambiente develop
│   │   ├── nexo-qa.yaml         # Apps ambiente qa
│   │   ├── nexo-staging.yaml    # Apps ambiente staging
│   │   └── nexo-prod.yaml       # Apps ambiente prod
│   └── projects/
│       └── nexo-environments.yaml  # Projetos ArgoCD
│
└── helm/
    ├── nexo-be/
    │   ├── values.yaml          # Valores base
    │   ├── values-dev.yaml      # Develop (develop)
    │   ├── values-qa.yaml       # QA (qa)
    │   ├── values-staging.yaml  # Staging (staging)
    │   └── values-prod.yaml     # Prod (main)
    │
    ├── nexo-fe/
    │   └── ...
    │
    └── nexo-auth/
        └── ...
```

---

## ✅ Checklist de Configuração

- [x] Pipeline detecta mudanças por serviço
- [x] Merge commits forçam build de todos os serviços
- [x] Tags de imagem usam branch-sha para imutabilidade
- [x] ArgoCD configurado para todos os ambientes
- [x] Helm values com podAnnotations para tracking
- [x] Script de promoção entre ambientes
- [x] Makefile com comandos de promoção

---

## 🔗 Links Úteis

- **GitHub Actions**: https://github.com/geraldobl58/nexo/actions
- **ArgoCD UI**: https://argocd.nexo.local
- **GHCR**: https://github.com/geraldobl58?tab=packages
