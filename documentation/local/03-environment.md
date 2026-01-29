# 03 - Ambientes

Configuração detalhada de todos os ambientes K3D.

---

## 🌍 Visão Geral dos Ambientes

| Ambiente    | Namespace    | Branch  | Propósito                |
| ----------- | ------------ | ------- | ------------------------ |
| **develop** | nexo-develop | develop | Desenvolvimento contínuo |
| **qa**      | nexo-qa      | qa      | Testes de QA             |
| **staging** | nexo-staging | staging | Homologação/Pré-prod     |
| **prod**    | nexo-prod    | main    | Produção                 |

---

## 🔗 URLs por Ambiente

### Develop

| Serviço        | URL                                  |
| -------------- | ------------------------------------ |
| Frontend       | http://develop.nexo.local            |
| Backend API    | http://develop.api.nexo.local        |
| Swagger        | http://develop.api.nexo.local/api    |
| Keycloak       | http://develop.auth.nexo.local       |
| Keycloak Admin | http://develop.auth.nexo.local/admin |

### QA

| Serviço        | URL                             |
| -------------- | ------------------------------- |
| Frontend       | http://qa.nexo.local            |
| Backend API    | http://qa.api.nexo.local        |
| Swagger        | http://qa.api.nexo.local/api    |
| Keycloak       | http://qa.auth.nexo.local       |
| Keycloak Admin | http://qa.auth.nexo.local/admin |

### Staging

| Serviço        | URL                                  |
| -------------- | ------------------------------------ |
| Frontend       | http://staging.nexo.local            |
| Backend API    | http://staging.api.nexo.local        |
| Swagger        | http://staging.api.nexo.local/api    |
| Keycloak       | http://staging.auth.nexo.local       |
| Keycloak Admin | http://staging.auth.nexo.local/admin |

### Prod

| Serviço        | URL                               |
| -------------- | --------------------------------- |
| Frontend       | http://prod.nexo.local            |
| Backend API    | http://prod.api.nexo.local        |
| Swagger        | http://prod.api.nexo.local/api    |
| Keycloak       | http://prod.auth.nexo.local       |
| Keycloak Admin | http://prod.auth.nexo.local/admin |

---

## 🖥️ Ferramentas (Acesso Direto)

| Ferramenta | URL                    | Credenciais      |
| ---------- | ---------------------- | ---------------- |
| ArgoCD     | http://localhost:30080 | admin / (\*)     |
| Prometheus | http://localhost:30090 | -                |
| Grafana    | http://localhost:30030 | admin / admin123 |

> (\*) Senha do ArgoCD:
>
> ```bash
> kubectl -n argocd get secret argocd-initial-admin-secret \
>   -o jsonpath="{.data.password}" | base64 -d
> ```

---

## 📝 Configuração do /etc/hosts

```bash
sudo nano /etc/hosts
```

Adicionar todas as entradas:

```
# ========================
# Nexo Platform - K3D
# ========================

# Develop
127.0.0.1 develop.nexo.local
127.0.0.1 develop.api.nexo.local
127.0.0.1 develop.auth.nexo.local

# QA
127.0.0.1 qa.nexo.local
127.0.0.1 qa.api.nexo.local
127.0.0.1 qa.auth.nexo.local

# Staging
127.0.0.1 staging.nexo.local
127.0.0.1 staging.api.nexo.local
127.0.0.1 staging.auth.nexo.local

# Prod
127.0.0.1 prod.nexo.local
127.0.0.1 prod.api.nexo.local
127.0.0.1 prod.auth.nexo.local
```

---

## ☸️ Cluster K3D

### Configuração

```yaml
# local/k3d/config.yaml
apiVersion: k3d.io/v1alpha5
kind: Simple
metadata:
  name: nexo-local
servers: 1
agents: 2
kubeAPI:
  hostIP: "0.0.0.0"
  hostPort: "6443"
ports:
  - port: 80:80
    nodeFilters: [loadbalancer]
  - port: 443:443
    nodeFilters: [loadbalancer]
  - port: 30080:30080
    nodeFilters: [servers:*]
  - port: 30030:30030
    nodeFilters: [servers:*]
  - port: 30090:30090
    nodeFilters: [servers:*]
```

### Portas Expostas

| Porta Host | Porta Container | Serviço                 |
| ---------- | --------------- | ----------------------- |
| 80         | 80              | Traefik Ingress (HTTP)  |
| 443        | 443             | Traefik Ingress (HTTPS) |
| 6443       | 6443            | Kubernetes API          |
| 30080      | 30080           | ArgoCD                  |
| 30030      | 30030           | Grafana                 |
| 30090      | 30090           | Prometheus              |

---

## 📦 Namespaces

```bash
# Verificar namespaces
kubectl get ns

# Namespaces da aplicação
nexo-develop    # Ambiente develop
nexo-qa         # Ambiente QA
nexo-staging    # Ambiente staging
nexo-prod       # Ambiente produção

# Namespaces de sistema
argocd          # ArgoCD GitOps
monitoring      # Prometheus + Grafana
kube-system     # Componentes K8s
```

### Criar Namespaces (caso necessário)

```bash
kubectl create namespace nexo-develop
kubectl create namespace nexo-qa
kubectl create namespace nexo-staging
kubectl create namespace nexo-prod
```

---

## 🔐 Secrets por Ambiente

### Estrutura de Secrets

Cada namespace tem seus próprios secrets:

```bash
# Listar secrets de um ambiente
kubectl get secrets -n nexo-develop

# Secrets comuns:
# - nexo-dockerhub-secret    (pull images do DockerHub)
# - nexo-auth-secrets        (credenciais Keycloak)
# - nexo-be-secrets          (credenciais Backend)
```

### DockerHub Secret

```bash
# Criar secret para pull de imagens
kubectl create secret docker-registry nexo-dockerhub-secret \
  --docker-server=docker.io \
  --docker-username=seu_usuario_dockerhub \
  --docker-password=<seu-token> \
  -n nexo-develop
```

---

## 📊 Recursos por Ambiente

### Develop / QA

```yaml
resources:
  requests:
    cpu: "100m"
    memory: "256Mi"
  limits:
    cpu: "500m"
    memory: "512Mi"
```

### Staging / Prod

```yaml
resources:
  requests:
    cpu: "250m"
    memory: "512Mi"
  limits:
    cpu: "1000m"
    memory: "1Gi"
```

### Keycloak (todos ambientes)

```yaml
resources:
  requests:
    cpu: "500m"
    memory: "1Gi"
  limits:
    cpu: "2000m"
    memory: "2Gi"
```

---

## 🔄 Variáveis de Ambiente

### nexo-fe (Frontend)

```env
NEXT_PUBLIC_API_URL=http://develop.api.nexo.local
NEXT_PUBLIC_AUTH_URL=http://develop.auth.nexo.local
```

### nexo-be (Backend)

```env
DATABASE_URL=postgresql://nexo:nexo123@nexo-be-postgresql:5432/nexo
KEYCLOAK_URL=http://nexo-auth:8080
KEYCLOAK_REALM=nexo
PORT=3333
```

### nexo-auth (Keycloak)

```env
KEYCLOAK_ADMIN=admin
KEYCLOAK_ADMIN_PASSWORD=admin
KC_DB=postgres
KC_DB_URL=jdbc:postgresql://nexo-auth-postgresql:5432/keycloak
KC_DB_USERNAME=keycloak
KC_DB_PASSWORD=keycloak123
KC_HOSTNAME=develop.auth.nexo.local
KC_PROXY=edge
KC_HTTP_ENABLED=true
```

---

## ➡️ Próximos Passos

- [04-github-setup.md](04-github-setup.md) - Configurar GitHub
- [05-cicd.md](05-cicd.md) - Pipeline CI/CD
