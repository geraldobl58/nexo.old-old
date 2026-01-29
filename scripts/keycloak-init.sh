#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# Keycloak Initialization Script
# Disables SSL requirement for local development on ALL realms
# ═══════════════════════════════════════════════════════════════════════════════

set -e

KEYCLOAK_URL="http://localhost:8080"
ADMIN_USER="admin"
ADMIN_PASSWORD="admin"
CONTAINER_NAME="nexo-auth-dev"

echo "⏳ Waiting for Keycloak to be ready..."
for i in {1..30}; do
  if curl -s "$KEYCLOAK_URL/health/ready" 2>/dev/null | grep -q "UP"; then
    echo "✅ Keycloak is ready!"
    break
  fi
  echo "   Attempt $i/30..."
  sleep 2
done

echo "🔧 Configuring kcadm credentials..."
docker exec $CONTAINER_NAME /opt/keycloak/bin/kcadm.sh config credentials \
  --server "$KEYCLOAK_URL" \
  --realm master \
  --user "$ADMIN_USER" \
  --password "$ADMIN_PASSWORD"

echo "🔓 Disabling SSL requirement for ALL realms..."

# Get all realms and disable SSL for each
REALMS=$(docker exec $CONTAINER_NAME /opt/keycloak/bin/kcadm.sh get realms 2>/dev/null | grep -o '"realm" : "[^"]*"' | cut -d'"' -f4)

for realm in $REALMS; do
  echo "   → Disabling SSL for realm: $realm"
  docker exec $CONTAINER_NAME /opt/keycloak/bin/kcadm.sh update realms/$realm -s sslRequired=NONE
done

echo ""
echo "✅ Keycloak configured for HTTP development!"
echo ""
echo "🔐 Access Keycloak:"
echo "   URL:    $KEYCLOAK_URL"
echo "   Admin:  $KEYCLOAK_URL/admin"
echo "   User:   $ADMIN_USER"
echo "   Pass:   $ADMIN_PASSWORD"
echo ""
echo "📦 Realms configured:"
for realm in $REALMS; do
  echo "   → $KEYCLOAK_URL/realms/$realm"
done
echo ""
