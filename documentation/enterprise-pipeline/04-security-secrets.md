# Security & Secrets Management

## 📋 Visão Geral

Segurança é não-negociável em pipelines enterprise. Esta seção documenta práticas de **zero-trust**, **zero-secrets-in-git** e **least-privilege** inspiradas em Netflix, Spotify e práticas CNCF.

## 🎯 Princípios de Segurança

```
┌─────────────────────────────────────────────────────────────────────┐
│                     SECURITY PRINCIPLES                              │
├─────────────────────────────────────────────────────────────────────┤
│  1. Zero Secrets in Git    → External Secrets Operator              │
│  2. Zero Long-Lived Tokens → OIDC (GitHub Actions ↔ Cloud)         │
│  3. Least Privilege        → RBAC granular (K8s + ArgoCD)           │
│  4. Immutable Artifacts    → Signed images, SBOM, provenance        │
│  5. Defense in Depth       → Network policies, admission control    │
│  6. Audit Everything       → Logs estruturados, Git history         │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 🔐 External Secrets Operator (ESO)

### Arquitetura

```
┌─────────────────────────────────────────────────────────────────────┐
│                    SECRETS FLOW                                      │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   AWS Secrets Manager / HashiCorp Vault                             │
│          │                                                           │
│          │ (1) ESO Controller polls secrets                         │
│          ▼                                                           │
│   SecretStore (K8s CRD)                                              │
│          │                                                           │
│          │ (2) ExternalSecret references SecretStore                │
│          ▼                                                           │
│   ExternalSecret (K8s CRD)                                           │
│          │                                                           │
│          │ (3) ESO syncs to native K8s Secret                       │
│          ▼                                                           │
│   Secret (K8s native)                                                │
│          │                                                           │
│          │ (4) Pod mounts secret                                    │
│          ▼                                                           │
│   Application consumes secrets                                       │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Instalação ESO

```bash
# Helm install
helm repo add external-secrets https://charts.external-secrets.io
helm repo update

helm install external-secrets \
  external-secrets/external-secrets \
  -n external-secrets-system \
  --create-namespace \
  --set installCRDs=true
```

### SecretStore Configuration

**Para AWS Secrets Manager**:

```yaml
# k8s/base/secretstore-aws.yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: aws-secrets-manager
  namespace: nexo-production
spec:
  provider:
    aws:
      service: SecretsManager
      region: us-east-1

      # Autenticação via IRSA (IAM Roles for Service Accounts)
      auth:
        jwt:
          serviceAccountRef:
            name: external-secrets-sa
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: external-secrets-sa
  namespace: nexo-production
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::123456789012:role/ExternalSecretsRole
```

**Para HashiCorp Vault**:

```yaml
# k8s/base/secretstore-vault.yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: vault-backend
  namespace: nexo-production
spec:
  provider:
    vault:
      server: "https://vault.example.com"
      path: "secret"
      version: "v2"

      auth:
        kubernetes:
          mountPath: "kubernetes"
          role: "nexo-production"
          serviceAccountRef:
            name: vault-sa
```

### ExternalSecret Examples

**Database Credentials**:

```yaml
# helm/nexo-be/templates/externalsecret-db.yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: {{ include "nexo-be.fullname" . }}-db
  namespace: {{ .Release.Namespace }}
spec:
  refreshInterval: 1h  # Sincroniza a cada hora

  secretStoreRef:
    name: aws-secrets-manager
    kind: SecretStore

  target:
    name: nexo-be-db-credentials  # Nome do Secret K8s gerado
    creationPolicy: Owner
    template:
      engineVersion: v2
      data:
        # Template permite transformações
        DATABASE_URL: "postgresql://{{ .username }}:{{ .password }}@{{ .host }}:{{ .port }}/{{ .database }}"

  data:
    - secretKey: username
      remoteRef:
        key: nexo/production/database
        property: username

    - secretKey: password
      remoteRef:
        key: nexo/production/database
        property: password

    - secretKey: host
      remoteRef:
        key: nexo/production/database
        property: host

    - secretKey: port
      remoteRef:
        key: nexo/production/database
        property: port

    - secretKey: database
      remoteRef:
        key: nexo/production/database
        property: database
```

**API Keys**:

```yaml
# helm/nexo-be/templates/externalsecret-api.yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: {{ include "nexo-be.fullname" . }}-api-keys
  namespace: {{ .Release.Namespace }}
spec:
  refreshInterval: 15m  # API keys rotacionam frequentemente

  secretStoreRef:
    name: aws-secrets-manager
    kind: SecretStore

  target:
    name: nexo-be-api-keys

  data:
    - secretKey: STRIPE_SECRET_KEY
      remoteRef:
        key: nexo/production/stripe
        property: secret_key

    - secretKey: SENDGRID_API_KEY
      remoteRef:
        key: nexo/production/sendgrid
        property: api_key
```

### Deployment Usage

```yaml
# helm/nexo-be/templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: { { include "nexo-be.fullname" . } }
spec:
  template:
    spec:
      containers:
        - name: nexo-be
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"

          # Inject secrets como variáveis de ambiente
          envFrom:
            - secretRef:
                name: nexo-be-db-credentials
            - secretRef:
                name: nexo-be-api-keys

          # Ou mount como arquivos (mais seguro)
          volumeMounts:
            - name: db-credentials
              mountPath: /secrets/db
              readOnly: true

      volumes:
        - name: db-credentials
          secret:
            secretName: nexo-be-db-credentials
```

---

## 🔑 OIDC: GitHub Actions → Cloud

### Por que OIDC?

**Problema com static tokens**:

```yaml
# ❌ NUNCA faça isso
- name: Deploy
  env:
    AWS_ACCESS_KEY_ID: AKIAIOSFODNN7EXAMPLE # Hardcoded!
    AWS_SECRET_ACCESS_KEY: wJalrXUtnFEMI/K7MDENG # Risco de vazamento
```

**Solução com OIDC**:

- ✅ Zero long-lived credentials
- ✅ Tokens de curta duração (1h)
- ✅ Revogação automática
- ✅ Audit trail completo

### Setup: AWS + GitHub OIDC

**1. IAM Identity Provider**:

```bash
# Criar OIDC provider na AWS
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

**2. IAM Role com Trust Policy**:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:nexo-org/nexo:ref:refs/heads/main"
        }
      }
    }
  ]
}
```

**3. GitHub Actions Workflow**:

```yaml
name: Deploy with OIDC

on:
  push:
    branches: [main]

permissions:
  id-token: write # CRITICAL: permite geração de OIDC token
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      # Autenticação via OIDC (zero secrets!)
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::123456789012:role/GitHubActionsRole
          role-session-name: GitHubActions-${{ github.run_id }}
          aws-region: us-east-1

      # Agora pode usar AWS CLI/SDK normalmente
      - name: Push to ECR
        run: |
          aws ecr get-login-password | docker login --username AWS --password-stdin 123456789012.dkr.ecr.us-east-1.amazonaws.com
          docker push 123456789012.dkr.ecr.us-east-1.amazonaws.com/nexo-be:${{ github.sha }}
```

### Setup: GCP + GitHub OIDC

**1. Workload Identity Pool**:

```bash
# Criar pool
gcloud iam workload-identity-pools create github-pool \
  --location="global" \
  --display-name="GitHub Actions Pool"

# Criar provider
gcloud iam workload-identity-pools providers create-oidc github-provider \
  --location="global" \
  --workload-identity-pool="github-pool" \
  --issuer-uri="https://token.actions.githubusercontent.com" \
  --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository" \
  --attribute-condition="assertion.repository=='nexo-org/nexo'"
```

**2. Service Account Binding**:

```bash
gcloud iam service-accounts add-iam-policy-binding github-actions-sa@PROJECT_ID.iam.gserviceaccount.com \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/github-pool/attribute.repository/nexo-org/nexo"
```

**3. GitHub Actions**:

```yaml
- name: Authenticate to GCP
  uses: google-github-actions/auth@v2
  with:
    workload_identity_provider: "projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/github-pool/providers/github-provider"
    service_account: "github-actions-sa@PROJECT_ID.iam.gserviceaccount.com"

- name: Push to GCR
  run: |
    gcloud auth configure-docker gcr.io
    docker push gcr.io/PROJECT_ID/nexo-be:${{ github.sha }}
```

---

## 🛡️ RBAC: Kubernetes & ArgoCD

### Kubernetes RBAC

**Namespaces Isolados**:

```yaml
# k8s/base/namespaces.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: nexo-production
  labels:
    environment: production
    team: nexo
---
apiVersion: v1
kind: Namespace
metadata:
  name: nexo-staging
  labels:
    environment: staging
    team: nexo
```

**ServiceAccount por Aplicação**:

```yaml
# helm/nexo-be/templates/serviceaccount.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ include "nexo-be.fullname" . }}
  namespace: {{ .Release.Namespace }}
  annotations:
    {{- if eq .Values.environment "production" }}
    eks.amazonaws.com/role-arn: arn:aws:iam::123456789012:role/NexoBEProductionRole
    {{- end }}
```

**RoleBinding (least privilege)**:

```yaml
# helm/nexo-be/templates/role.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: { { include "nexo-be.fullname" . } }
  namespace: { { .Release.Namespace } }
rules:
  # Apenas o necessário para a aplicação
  - apiGroups: [""]
    resources: ["configmaps"]
    verbs: ["get", "list"]

  - apiGroups: [""]
    resources: ["secrets"]
    verbs: ["get"] # Read-only
    resourceNames:
      - nexo-be-db-credentials
      - nexo-be-api-keys
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: { { include "nexo-be.fullname" . } }
  namespace: { { .Release.Namespace } }
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: { { include "nexo-be.fullname" . } }
subjects:
  - kind: ServiceAccount
    name: { { include "nexo-be.fullname" . } }
    namespace: { { .Release.Namespace } }
```

### ArgoCD RBAC

**Ver**: [02-argocd-configuration.md](02-argocd-configuration.md#rbac-dentro-do-projeto) para detalhes completos.

**Resumo**:

- **Developers**: Read-only + sync develop/qa
- **Platform Engineers**: Full access (exceto produção)
- **SRE**: Full access (incluindo produção)

---

## 🔏 Image Signing & Verification

### Cosign (Sigstore)

**1. Gerar keypair**:

```bash
# Gerar chaves
cosign generate-key-pair

# Armazenar em GitHub Secrets
# COSIGN_PRIVATE_KEY → Private key
# COSIGN_PASSWORD → Password da chave
# COSIGN_PUBLIC_KEY → Public key (pode ser público)
```

**2. Assinar imagem no CI**:

```yaml
# .github/workflows/_reusable-ci.yml
- name: Sign container image
  env:
    COSIGN_PRIVATE_KEY: ${{ secrets.COSIGN_PRIVATE_KEY }}
    COSIGN_PASSWORD: ${{ secrets.COSIGN_PASSWORD }}
  run: |
    echo "$COSIGN_PRIVATE_KEY" > cosign.key
    cosign sign --key cosign.key \
      ghcr.io/nexo-org/nexo-be:${{ needs.version.outputs.version }}
    rm cosign.key
```

**3. Verificar no deploy**:

```bash
# Manual verification
cosign verify --key cosign.pub \
  ghcr.io/nexo-org/nexo-be:2026.02.1
```

**4. Admission Controller (Kyverno)**:

```yaml
# k8s/base/policy-verify-images.yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: verify-images
spec:
  validationFailureAction: enforce
  background: false
  rules:
    - name: verify-nexo-images
      match:
        any:
          - resources:
              kinds:
                - Pod
              namespaces:
                - nexo-production
      verifyImages:
        - imageReferences:
            - "ghcr.io/nexo-org/*"
          attestors:
            - entries:
                - keys:
                    publicKeys: |
                      -----BEGIN PUBLIC KEY-----
                      MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE...
                      -----END PUBLIC KEY-----
```

---

## 🔍 SBOM & Vulnerability Scanning

### SBOM Generation (Syft)

```yaml
# .github/workflows/_reusable-ci.yml
- name: Generate SBOM
  uses: anchore/sbom-action@v0
  with:
    image: ghcr.io/nexo-org/nexo-be:${{ needs.version.outputs.version }}
    format: spdx-json
    output-file: sbom.spdx.json

- name: Upload SBOM to release
  uses: actions/upload-artifact@v4
  with:
    name: sbom-${{ needs.version.outputs.version }}
    path: sbom.spdx.json
```

### Vulnerability Scanning (Trivy)

```yaml
- name: Run Trivy scanner
  uses: aquasecurity/trivy-action@master
  with:
    image-ref: ghcr.io/nexo-org/nexo-be:${{ needs.version.outputs.version }}
    format: "sarif"
    output: "trivy-results.sarif"
    severity: "CRITICAL,HIGH"
    exit-code: "1" # Fail CI se encontrar vulns

- name: Upload to GitHub Security
  uses: github/codeql-action/upload-sarif@v3
  if: always()
  with:
    sarif_file: "trivy-results.sarif"
```

---

## 🌐 Network Policies

```yaml
# helm/nexo-be/templates/networkpolicy.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: { { include "nexo-be.fullname" . } }
  namespace: { { .Release.Namespace } }
spec:
  podSelector:
    matchLabels:
      app: { { include "nexo-be.name" . } }

  policyTypes:
    - Ingress
    - Egress

  # Ingress: apenas do ingress controller
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              name: ingress-nginx
        - podSelector:
            matchLabels:
              app.kubernetes.io/name: ingress-nginx
      ports:
        - protocol: TCP
          port: 8080

  # Egress: apenas o necessário
  egress:
    # DNS
    - to:
        - namespaceSelector:
            matchLabels:
              name: kube-system
        - podSelector:
            matchLabels:
              k8s-app: kube-dns
      ports:
        - protocol: UDP
          port: 53

    # Database
    - to:
        - podSelector:
            matchLabels:
              app: postgres
      ports:
        - protocol: TCP
          port: 5432

    # External APIs (exemplo: Stripe, SendGrid)
    - to:
        - namespaceSelector: {}
      ports:
        - protocol: TCP
          port: 443
```

---

## 🔐 Secrets Rotation

### Automated Rotation with AWS Secrets Manager

```python
# scripts/rotate-db-password.py
import boto3
import psycopg2
import secrets
import string

def generate_password(length=32):
    alphabet = string.ascii_letters + string.digits + "!@#$%^&*"
    return ''.join(secrets.choice(alphabet) for _ in range(length))

def rotate_secret(secret_name):
    client = boto3.client('secretsmanager', region_name='us-east-1')

    # 1. Obter secret atual
    response = client.get_secret_value(SecretId=secret_name)
    current = json.loads(response['SecretString'])

    # 2. Gerar nova senha
    new_password = generate_password()

    # 3. Atualizar no banco
    conn = psycopg2.connect(
        host=current['host'],
        user=current['username'],
        password=current['password'],
        database='postgres'
    )
    cursor = conn.cursor()
    cursor.execute(f"ALTER USER {current['username']} PASSWORD '{new_password}'")
    conn.commit()
    conn.close()

    # 4. Atualizar secret
    new_secret = {**current, 'password': new_password}
    client.update_secret(
        SecretId=secret_name,
        SecretString=json.dumps(new_secret)
    )

    print(f"✅ Secret {secret_name} rotated successfully")

if __name__ == '__main__':
    rotate_secret('nexo/production/database')
```

---

## 📋 Security Checklist

### CI/CD Pipeline

- ✅ OIDC configurado (zero static tokens)
- ✅ SAST rodando (Semgrep/SonarCloud)
- ✅ Dependency scanning (Snyk/Trivy)
- ✅ Container image scanning
- ✅ SBOM gerado para cada build
- ✅ Imagens assinadas (Cosign)
- ✅ Secrets nunca em logs
- ✅ Artifacts assinados (provenance)

### Kubernetes

- ✅ RBAC configurado (least privilege)
- ✅ Network policies aplicadas
- ✅ PodSecurityStandards enforced
- ✅ Service accounts únicos por app
- ✅ Secrets encrypted at rest
- ✅ Admission controller (Kyverno/OPA)
- ✅ Resource limits configurados
- ✅ Security contexts (runAsNonRoot, etc.)

### Secrets Management

- ✅ External Secrets Operator instalado
- ✅ Secrets em AWS Secrets Manager/Vault
- ✅ Rotation policy configurada
- ✅ Audit logging habilitado
- ✅ Acesso via IAM roles (não API keys)

### Compliance

- ✅ Audit logs centralizados
- ✅ Git history preservado
- ✅ Aprovações documentadas (PRs)
- ✅ Vulnerability SLA: CRITICAL < 24h
- ✅ Penetration testing (anual)

---

**Próximo**: [Observability & Governance](05-observability.md)
