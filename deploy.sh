#!/bin/bash

# Script de despliegue para bot-meta-plantilla en producción
# Uso: ./deploy.sh

set -e

echo "🚀 Iniciando despliegue de Bot Meta WhatsApp..."

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

# Verificar que estamos en la carpeta correcta
if [ ! -f "docker-compose.yml" ]; then
    log_error "docker-compose.yml no encontrado. ¿Estás en la carpeta correcta?"
    exit 1
fi

# Verificar que existe .env
if [ ! -f ".env" ]; then
    log_error "Archivo .env no encontrado. Copia .env.example a .env y configura las variables."
    exit 1
fi

# Verificar que la red compartida existe
log_info "Verificando red compartida..."
if ! docker network ls | grep -q "shared_network"; then
    log_info "Creando red compartida shared_network..."
    docker network create shared_network
else
    log_info "Red shared_network ya existe"
fi

# Parar servicios si están corriendo
log_info "Parando servicios existentes..."
docker-compose down --remove-orphans

# Limpiar imágenes viejas
log_info "Limpiando imágenes antiguas..."
docker image prune -f

# Construir nueva imagen
log_info "Construyendo nueva imagen..."
docker-compose build --no-cache

# Iniciar servicios
log_info "Iniciando servicios..."
docker-compose up -d

# Esperar a que el servicio esté listo
log_info "Esperando a que el servicio esté listo..."
sleep 30

# Verificar que el servicio está funcionando
log_info "Verificando salud del servicio..."
if docker-compose ps | grep -q "Up"; then
    log_info "✅ Servicio iniciado exitosamente"
    
    # Mostrar logs
    log_info "Mostrando logs recientes..."
    docker-compose logs --tail=20
    
    # Probar health check
    log_info "Probando health check..."
    if curl -f -s --max-time 10 "http://localhost:3008/health" > /dev/null; then
        log_info "✅ Health check exitoso"
        log_info "🎉 Despliegue completado exitosamente!"
        log_info "📱 Bot Meta WhatsApp disponible en: http://localhost:3008"
        log_info "🔍 Health check: http://localhost:3008/health"
        log_info "ℹ️  Info del bot: http://localhost:3008/bot/info"
    else
        log_warning "⚠️ Health check falló, pero el servicio parece estar corriendo"
        log_info "Revisa los logs: docker-compose logs -f"
    fi
else
    log_error "❌ Error al iniciar el servicio"
    log_error "Revisa los logs: docker-compose logs"
    exit 1
fi

echo ""
log_info "🔧 Comandos útiles:"
echo "  • Ver logs:           docker-compose logs -f"
echo "  • Reiniciar:          docker-compose restart"
echo "  • Parar:              docker-compose down"
echo "  • Estado:             docker-compose ps"
echo "  • Health check:       curl http://localhost:3008/health"
