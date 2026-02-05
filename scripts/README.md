# Scripts CI/CD

Scripts utilizados exclusivamente pelos workflows do GitHub Actions.

## 📋 Scripts Disponíveis

### CI/CD Automation

- **`promote.sh`** - Promove versões entre ambientes (develop → qa → staging → prod)
- **`validate-deploy.sh`** - Valida deployments após sincronização do ArgoCD
- **`setup-pipeline.sh`** - Configura secrets e recursos necessários para pipeline
- **`keycloak-init.sh`** - Inicializa configurações do Keycloak

## ⚠️ Importante

**Estes scripts são executados automaticamente pelo GitHub Actions.**

Para gerenciar o ambiente local, use os scripts em `/local/scripts/`:

```bash
# Setup completo do ambiente local
cd local && ./scripts/setup.sh ghp_YOUR_TOKEN

# Destruir ambiente
cd local && ./scripts/destroy.sh

# Ver status
cd local && ./scripts/status.sh
```

## 🔄 Fluxo de CI/CD

```
develop → qa → staging → prod
   ↓       ↓       ↓        ↓
 Auto    Auto    Auto   Manual
```

- **develop**: Deploy automático ao fazer push
- **qa**: Promoção manual via `promote.sh`
- **staging**: Promoção manual via `promote.sh`
- **prod**: Promoção manual com aprovação via GitHub Actions

## 📚 Documentação

Para mais detalhes sobre o fluxo de CI/CD, veja:
- `/documentation/enterprise-pipeline/`
- `/documentation/local/05-cicd.md`
