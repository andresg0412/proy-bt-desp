#!/bin/bash

# Script para configurar la red compartida entre proyectos
# Uso: ./setup-shared-network.sh

set -e

echo "🌐 Configurando red compartida para múltiples proyectos Docker..."

# Colores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
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

# Verificar si Docker está corriendo
if ! docker info > /dev/null 2>&1; then
    log_error "Docker no está corriendo o no tienes permisos"
    exit 1
fi

# Verificar si la red ya existe
if docker network ls | grep -q "shared_network"; then
    log_warning "La red 'shared_network' ya existe"
    
    # Mostrar información de la red
    log_info "Información de la red existente:"
    docker network inspect shared_network --format "{{json .IPAM.Config}}" | head -1
    
    # Preguntar si quiere recrearla
    read -p "¿Deseas recrear la red? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Eliminando red existente..."
        
        # Desconectar contenedores si los hay
        CONTAINERS=$(docker network inspect shared_network --format '{{range .Containers}}{{.Name}} {{end}}' 2>/dev/null || true)
        if [ ! -z "$CONTAINERS" ]; then
            log_warning "Desconectando contenedores: $CONTAINERS"
            for container in $CONTAINERS; do
                docker network disconnect shared_network $container 2>/dev/null || true
            done
        fi
        
        docker network rm shared_network
    else
        log_info "Manteniendo red existente"
        exit 0
    fi
fi

# Crear la red compartida
log_info "Creando red compartida 'shared_network'..."
docker network create \
    --driver bridge \
    --subnet=172.20.0.0/16 \
    --ip-range=172.20.240.0/20 \
    --gateway=172.20.0.1 \
    shared_network

if [ $? -eq 0 ]; then
    log_info "✅ Red 'shared_network' creada exitosamente"
    
    # Mostrar información de la red
    log_info "📋 Información de la red:"
    docker network inspect shared_network --format "Driver: {{.Driver}}"
    docker network inspect shared_network --format "Subnet: {{range .IPAM.Config}}{{.Subnet}}{{end}}"
    docker network inspect shared_network --format "Gateway: {{range .IPAM.Config}}{{.Gateway}}{{end}}"
    
    echo ""
    log_info "🔧 Uso en docker-compose.yml:"
    echo "networks:"
    echo "  shared_network:"
    echo "    external: true"
    echo "    name: shared_network"
    
    echo ""
    log_info "💡 Comandos útiles:"
    echo "  • Ver redes:           docker network ls"
    echo "  • Inspeccionar red:    docker network inspect shared_network"
    echo "  • Eliminar red:        docker network rm shared_network"
    echo "  • Ver contenedores:    docker network inspect shared_network --format '{{range .Containers}}{{.Name}} {{end}}'"
    
else
    log_error "❌ Error al crear la red compartida"
    exit 1
fi
