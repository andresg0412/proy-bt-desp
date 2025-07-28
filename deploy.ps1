# Script de despliegue para bot-meta-plantilla en Windows
# Uso: .\deploy.ps1

param(
    [switch]$SkipBuild,
    [switch]$SkipHealthCheck
)

Write-Host "🚀 Iniciando despliegue de Bot Meta WhatsApp..." -ForegroundColor Green

function Log-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Green
}

function Log-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Log-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Verificar que estamos en la carpeta correcta
if (!(Test-Path "docker-compose.yml")) {
    Log-Error "docker-compose.yml no encontrado. ¿Estás en la carpeta correcta?"
    exit 1
}

# Verificar que existe .env
if (!(Test-Path ".env")) {
    Log-Error "Archivo .env no encontrado. Copia .env.example a .env y configura las variables."
    exit 1
}

try {
    # Verificar que la red compartida existe
    Log-Info "Verificando red compartida..."
    $networkExists = docker network ls --format "{{.Name}}" | Select-String -Pattern "shared_network"
    
    if (!$networkExists) {
        Log-Info "Creando red compartida shared_network..."
        docker network create shared_network
        if ($LASTEXITCODE -ne 0) {
            Log-Warning "No se pudo crear la red, puede que ya exista"
        }
    } else {
        Log-Info "Red shared_network ya existe"
    }

    # Parar servicios si están corriendo
    Log-Info "Parando servicios existentes..."
    docker-compose down --remove-orphans

    if (!$SkipBuild) {
        # Limpiar imágenes viejas
        Log-Info "Limpiando imágenes antiguas..."
        docker image prune -f

        # Construir nueva imagen
        Log-Info "Construyendo nueva imagen..."
        docker-compose build --no-cache
        
        if ($LASTEXITCODE -ne 0) {
            Log-Error "Error en la construcción de la imagen"
            exit 1
        }
    }

    # Iniciar servicios
    Log-Info "Iniciando servicios..."
    docker-compose up -d
    
    if ($LASTEXITCODE -ne 0) {
        Log-Error "Error al iniciar los servicios"
        exit 1
    }

    # Esperar a que el servicio esté listo
    Log-Info "Esperando a que el servicio esté listo..."
    Start-Sleep -Seconds 30

    # Verificar que el servicio está funcionando
    Log-Info "Verificando salud del servicio..."
    $serviceStatus = docker-compose ps --format "table {{.Service}}\t{{.Status}}"
    Write-Host $serviceStatus

    if ($serviceStatus -match "Up") {
        Log-Info "✅ Servicio iniciado exitosamente"
        
        # Mostrar logs
        Log-Info "Mostrando logs recientes..."
        docker-compose logs --tail=20

        if (!$SkipHealthCheck) {
            # Probar health check
            Log-Info "Probando health check..."
            try {
                $response = Invoke-WebRequest -Uri "http://localhost:3008/health" -Method GET -TimeoutSec 10
                if ($response.StatusCode -eq 200) {
                    Log-Info "✅ Health check exitoso"
                    Log-Info "🎉 Despliegue completado exitosamente!"
                    Log-Info "📱 Bot Meta WhatsApp disponible en: http://localhost:3008"
                    Log-Info "🔍 Health check: http://localhost:3008/health"
                    Log-Info "ℹ️  Info del bot: http://localhost:3008/bot/info"
                } else {
                    Log-Warning "⚠️ Health check falló con código: $($response.StatusCode)"
                }
            } catch {
                Log-Warning "⚠️ Health check falló, pero el servicio parece estar corriendo"
                Log-Info "Revisa los logs: docker-compose logs -f"
            }
        }
    } else {
        Log-Error "❌ Error al iniciar el servicio"
        Log-Error "Revisa los logs: docker-compose logs"
        exit 1
    }

    Write-Host ""
    Log-Info "🔧 Comandos útiles:"
    Write-Host "  • Ver logs:           docker-compose logs -f"
    Write-Host "  • Reiniciar:          docker-compose restart"
    Write-Host "  • Parar:              docker-compose down"
    Write-Host "  • Estado:             docker-compose ps"
    Write-Host "  • Health check:       Invoke-WebRequest -Uri http://localhost:3008/health"

} catch {
    Log-Error "Error durante el despliegue: $($_.Exception.Message)"
    exit 1
}
