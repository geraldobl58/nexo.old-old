# ============================================================================
# Dockerfile - Nexo Auth (Keycloak com Temas Customizados)
# ============================================================================
# Para atualizar a versão, mude KEYCLOAK_VERSION aqui e no docker-compose.yml
# ============================================================================

ARG KEYCLOAK_VERSION=26.5

FROM quay.io/keycloak/keycloak:${KEYCLOAK_VERSION} AS builder

# Copiar temas customizados
# O contexto do build é a raiz do projeto (nexo/)
COPY apps/nexo-auth/themes/ /opt/keycloak/themes/

# Build otimizado para produção
RUN /opt/keycloak/bin/kc.sh build

# ============================================================================
# Runtime Stage
# ============================================================================
ARG KEYCLOAK_VERSION=26.5
FROM quay.io/keycloak/keycloak:${KEYCLOAK_VERSION}

COPY --from=builder /opt/keycloak/ /opt/keycloak/

# Configurações padrão
ENV KC_HEALTH_ENABLED=true
ENV KC_METRICS_ENABLED=true

ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]
