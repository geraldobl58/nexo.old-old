# Configuração de Volumes no SSD Externo

Este documento explica como o projeto Nexo está configurado para usar um SSD externo para armazenar volumes Docker, economizando espaço no disco interno do MacBook.

## 📋 Visão Geral

Todos os volumes Docker foram configurados para usar o SSD externo montado em:

```
/Volumes/Backup/DockerSSD
```

### Volumes Mapeados

#### Nexo (Produção) - `docker-compose.yml`

```
/Volumes/Backup/DockerSSD/nexo/
├── postgres/      → PostgreSQL data
└── keycloak/      → Keycloak data
```

#### Nexo Dev - `local/docker/compose/dev/docker-compose.yml`

```
/Volumes/Backup/DockerSSD/nexo-dev/
├── postgres/      → PostgreSQL data
├── redis/         → Redis cache
├── keycloak/      → Keycloak data
├── api-uploads/   → API file uploads
├── prometheus/    → Métricas
├── grafana/       → Dashboards
└── loki/          → Logs
```

## 🚀 Configuração Automática

A configuração do SSD é feita automaticamente pelo script de setup principal:

```bash
cd local
./scripts/setup.sh
```

O script irá:

1. ✅ Verificar se o SSD está conectado em `/Volumes/Backup/DockerSSD`
2. ✅ Criar automaticamente toda a estrutura de diretórios
3. ✅ Configurar permissões adequadas
4. ⚠️ Se o SSD não estiver conectado, pergunta se deseja continuar com volumes locais

## 🎯 Uso Diário

### Opção 1: Usando o Script de Setup (Recomendado)

**O script cria automaticamente toda a estrutura necessária:**

```bash
# Verificar se o SSD está montado
ls -la /Volumes/Backup/DockerSSD

# Executar o setup (cria diretórios automaticamente)
cd local
./scripts/setup.sh
```

### Opção 2: Criação Manual (Para Docker Compose na Raiz)

**Se for usar `docker compose up -d` diretamente na raiz do projeto, crie os diretórios primeiro:**

```bash
# Criar estrutura para Nexo (Produção)
mkdir -p /Volumes/Backup/DockerSSD/nexo/postgres
mkdir -p /Volumes/Backup/DockerSSD/nexo/keycloak
chmod -R 777 /Volumes/Backup/DockerSSD/nexo

# Criar estrutura para Nexo Dev (opcional)
mkdir -p /Volumes/Backup/DockerSSD/nexo-dev/{postgres,redis,keycloak,api-uploads,prometheus,grafana,loki}
chmod -R 777 /Volumes/Backup/DockerSSD/nexo-dev
```

⚠️ **IMPORTANTE**: Os diretórios devem existir antes de executar `docker compose up -d`, caso contrário você verá o erro:

```
failed to populate volume: no such file or directory
```

### Iniciar Ambiente

```bash
# Produção (docker-compose raiz)
docker compose up -d

# Desenvolvimento (com observabilidade)
cd local/docker/compose/dev
docker compose up -d
```

## 💡 Vantagens

1. **Espaço Livre no Mac**: Volumes pesados ficam no SSD externo
2. **Performance**: SSDs externos USB-C têm boa performance
3. **Backup Simplificado**: Basta copiar a pasta do SSD
4. **Isolamento**: Dados de desenvolvimento separados do sistema
5. **Setup Automático**: Integrado no script principal de setup

## ⚙️ Configuração Técnica

Os volumes são configurados usando `driver_opts` do Docker:

```yaml
volumes:
  postgres-data:
    name: nexo-postgres-data
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /Volumes/Backup/DockerSSD/nexo/postgres
```

Isso cria um bind mount que mapeia o volume Docker para um diretório específico no SSD.

## 🔧 Troubleshooting

### Erro: "no such file or directory"

Se você ver o erro ao executar `docker compose up -d`:

```
failed to populate volume: no such file or directory
```

**Solução**: Crie a estrutura de diretórios antes de iniciar:

```bash
# Opção 1: Usar o Makefile
make ssd-setup

# Opção 2: Criar manualmente
mkdir -p /Volumes/Backup/DockerSSD/nexo/postgres
mkdir -p /Volumes/Backup/DockerSSD/nexo/keycloak
chmod -R 777 /Volumes/Backup/DockerSSD/nexo
```

### Erro: "Operation not permitted" (Arquivos `._*`)

Se o PostgreSQL falhar com erros de "Operation not permitted" relacionados a arquivos `._*`:

**Causa**: O macOS cria arquivos AppleDouble (`._*`) em discos exFAT que causam conflito com o PostgreSQL.

**Solução**:

```bash
# 1. Parar containers
docker compose down -v

# 2. Limpar diretórios
rm -rf /Volumes/Backup/DockerSSD/nexo/postgres/*
rm -rf /Volumes/Backup/DockerSSD/nexo/keycloak/*

# 3. Reiniciar
docker compose up -d
```

**Prevenção**: Se possível, formate o SSD como **APFS** ou **HFS+** em vez de exFAT para melhor compatibilidade.

### Erro: "Volume not found"

Se você encontrar erros de volume não encontrado:

1. Verifique se o SSD está conectado:

   ```bash
   ls -la /Volumes/Backup/DockerSSD
   ```

2. Re-execute o setup:
   ```bash
   cd local
   ./scripts/setup.sh
   ```

### Erro: "Permission denied"

Se você encontrar erros de permissão:

```bash
# Ajustar permissões manualmente
chmod -R 777 /Volumes/Backup/DockerSSD/nexo
chmod -R 777 /Volumes/Backup/DockerSSD/nexo-dev
```

### SSD Desconectado Durante Execução

Se o SSD for desconectado enquanto os containers estão rodando:

1. **NÃO desligue os containers ainda**
2. Reconecte o SSD no mesmo caminho
3. Reinicie os containers:
   ```bash
   docker compose restart
   ```

### Reverter para Volumes Locais

Se você quiser voltar a usar volumes locais do Docker:

1. Edite os arquivos docker-compose e remova as seções `driver_opts`:
   - [docker-compose.yml](../../docker-compose.yml)
   - [local/docker/compose/dev/docker-compose.yml](../../local/docker/compose/dev/docker-compose.yml)

2. Remova os containers e volumes:

   ```bash
   docker compose down -v
   ```

3. Inicie novamente:
   ```bash
   docker compose up -d
   ```

## 📊 Monitoramento de Espaço

Para verificar o espaço usado no SSD:

```bash
# Tamanho total dos volumes
du -sh /Volumes/Backup/DockerSSD/nexo*

# Detalhado por serviço
du -sh /Volumes/Backup/DockerSSD/nexo-dev/*

# Espaço disponível
df -h /Volumes/Backup/DockerSSD
```

Ou usando o Makefile:

```bash
make ssd-status
```

## 🔄 Migração de Dados Existentes

Se você já possui volumes Docker com dados e quer migrá-los para o SSD:

```bash
# 1. Parar containers
docker compose down
cd local/docker/compose/dev
docker compose down

# 2. Copiar dados do volume antigo para o SSD
docker run --rm \
  -v nexo-postgres-data:/from \
  -v /Volumes/Backup/DockerSSD/nexo/postgres:/to \
  alpine sh -c "cd /from && cp -av . /to"

# 3. Remover volumes antigos
docker volume rm nexo-postgres-data

# 4. Reiniciar
docker compose up -d
```

## 📝 Notas Importantes

1. **SSD Sempre Conectado**: Certifique-se de que o SSD esteja conectado antes de iniciar containers
2. **Performance**: A performance pode variar dependendo da conexão USB (recomendado USB-C 3.1+)
3. **Portabilidade**: Você pode levar o SSD e conectar em outro Mac mantendo todos os dados
4. **Múltiplos Ambientes**: Os dados de prod e dev ficam separados em diretórios diferentes
5. **Backup Automático**: Configure o Time Machine para incluir o SSD externo

## 🆘 Comandos Úteis (Makefile)

```bash
# Verificar status do SSD
make ssd-status

# Limpar volumes do SSD (CUIDADO!)
make ssd-clean
```
