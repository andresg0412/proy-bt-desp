#!/bin/bash

# Script para verificar la configuración del bot-meta antes del despliegue
# Uso: ./check-config.sh

set -e

echo "🔧 Verificando configuración de Bot Meta WhatsApp..."

# Colores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para logging
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_section() {
    echo -e "${BLUE}[SECTION]${NC} $1"
}

# Contador de errores
errors=0

# Verificar que estamos en la carpeta correcta
if [ ! -f "docker-compose.yml" ]; then
    log_error "docker-compose.yml no encontrado. ¿Estás en la carpeta correcta?"
    ((errors++))
fi

# Verificar archivo .env
log_section "📋 Verificando archivo .env..."
if [ ! -f ".env" ]; then
    log_error "Archivo .env no encontrado"
    log_info "💡 Solución: cp .env.example .env && nano .env"
    ((errors++))
else
    log_info "✅ Archivo .env encontrado"
    
    # Verificar variables críticas
    required_vars=(
        "BOT_PORT"
        "JWT_TOKEN"
        "NUMBER_ID"
        "VERIFY_TOKEN"
        "URL_SHEETBEST"
        "API_KEY_SHEETBEST"
        "API_BACKEND_URL"
        "EXTERNAL_NETWORK_NAME"
        "EXTERNAL_BOT_PORT"
    )
    
    for var in "${required_vars[@]}"; do
        if grep -q "^$var=" .env; then
            value=$(grep "^$var=" .env | cut -d'=' -f2-)
            if [ -z "$value" ] || [ "$value" = "your_token_here" ] || [ "$value" = "your_api_key_here" ]; then
                log_warning "⚠️ Variable $var no configurada o usa valor por defecto"
                ((errors++))
            else
                log_info "✅ $var configurado"
            fi
        else
            log_error "❌ Variable $var no encontrada en .env"
            ((errors++))
        fi
    done
fi

# Verificar Docker
log_section "🐳 Verificando Docker..."
if command -v docker &> /dev/null; then
    log_info "✅ Docker instalado"
    if docker info > /dev/null 2>&1; then
        log_info "✅ Docker está corriendo"
    else
        log_error "❌ Docker no está corriendo"
        ((errors++))
    fi
else
    log_error "❌ Docker no está instalado"
    ((errors++))
fi

if command -v docker-compose &> /dev/null; then
    log_info "✅ Docker Compose instalado"
else
    log_error "❌ Docker Compose no está instalado"
    ((errors++))
fi

# Verificar red compartida
log_section "🌐 Verificando red compartida..."
if docker network ls | grep -q "shared_network"; then
    log_info "✅ Red shared_network existe"
else
    log_warning "⚠️ Red shared_network no existe"
    log_info "💡 Solución: ./setup-shared-network.sh o docker network create shared_network"
fi

# Verificar puertos
log_section "🔌 Verificando puertos..."
if [ -f ".env" ]; then
    BOT_PORT=$(grep "^EXTERNAL_BOT_PORT=" .env | cut -d'=' -f2 || echo "3008")
    if netstat -tuln 2>/dev/null | grep -q ":$BOT_PORT "; then
        log_warning "⚠️ Puerto $BOT_PORT ya está en uso"
        log_info "Procesos usando el puerto:"
        lsof -i :$BOT_PORT 2>/dev/null || netstat -tulpn 2>/dev/null | grep ":$BOT_PORT "
    else
        log_info "✅ Puerto $BOT_PORT disponible"
    fi
fi

# Verificar archivos del proyecto
log_section "📁 Verificando archivos del proyecto..."
required_files=(
    "bot-meta/Dockerfile"
    "bot-meta/package.json"
    "bot-meta/src/app.ts"
    "bot-meta/tsconfig.json"
    "docker-compose.yml"
    ".env.example"
)

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        log_info "✅ $file encontrado"
    else
        log_error "❌ $file no encontrado"
        ((errors++))
    fi
done

# Verificar package.json
log_section "📦 Verificando package.json..."
if [ -f "bot-meta/package.json" ]; then
    if grep -q '"@builderbot/bot"' bot-meta/package.json; then
        log_info "✅ Dependencia @builderbot/bot encontrada"
    else
        log_error "❌ Dependencia @builderbot/bot no encontrada"
        ((errors++))
    fi
    
    if grep -q '"@builderbot/provider-meta"' bot-meta/package.json; then
        log_info "✅ Dependencia @builderbot/provider-meta encontrada"
    else
        log_error "❌ Dependencia @builderbot/provider-meta no encontrada"
        ((errors++))
    fi
    
    if grep -q '"start"' bot-meta/package.json; then
        log_info "✅ Script 'start' encontrado"
    else
        log_error "❌ Script 'start' no encontrado en package.json"
        ((errors++))
    fi
fi

# Verificar conectividad (si la red ya existe)
log_section "🔗 Verificando conectividad..."
if docker network ls | grep -q "shared_network"; then
    # Intentar hacer ping al backend si existe
    if docker ps --format "{{.Names}}" | grep -q "backend"; then
        log_info "Probando conectividad con backend..."
        if docker run --rm --network shared_network alpine ping -c 1 backend > /dev/null 2>&1; then
            log_info "✅ Conectividad con backend exitosa"
        else
            log_warning "⚠️ No se puede conectar con backend (puede no estar corriendo)"
        fi
    else
        log_info "Backend no está corriendo (normal en primera instalación)"
    fi
fi

# Resumen final
log_section "📊 Resumen de verificación..."
if [ $errors -eq 0 ]; then
    log_info "🎉 ¡Configuración completa y correcta!"
    log_info "✅ Listo para desplegar con: ./deploy.sh"
    echo ""
    log_info "📝 Próximos pasos:"
    echo "   1. Ejecutar: ./deploy.sh"
    echo "   2. Verificar: curl http://localhost:3008/health"
    echo "   3. Configurar webhook en Meta con tu dominio/ngrok"
else
    log_error "❌ Se encontraron $errors errores"
    log_info "💡 Corrige los errores antes de continuar con el despliegue"
    exit 1
fi
