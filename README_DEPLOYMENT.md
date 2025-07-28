# Bot Meta WhatsApp - Despliegue en Producción

## 🚀 Guía de Despliegue con Docker

### Prerrequisitos

1. **Docker y Docker Compose** instalados
2. **Red compartida configurada** (para comunicación con proyecto-ips)
3. **Variables de entorno configuradas**

### Pasos para Despliegue

#### 1. Configurar Variables de Entorno

```bash
# Copiar archivo de ejemplo
cp .env.example .env

# Editar variables según tu configuración
nano .env
```

**Variables críticas a configurar:**
- `JWT_TOKEN`: Token JWT de Meta WhatsApp Business API
- `NUMBER_ID`: ID del número de teléfono registrado en Meta
- `VERIFY_TOKEN`: Token de verificación para webhook
- `URL_SHEETBEST`: URL de tu Google Sheet vía SheetBest
- `API_KEY_SHEETBEST`: API Key de SheetBest

#### 2. Configurar Red Compartida

```bash
# Para Linux/Mac
./setup-shared-network.sh

# O manualmente
docker network create shared_network
```

#### 3. Desplegar Aplicación

```bash
# Para Linux/Mac
./deploy.sh

# Para Windows
.\deploy.ps1
```

#### 4. Verificar Despliegue

```bash
# Verificar estado
docker-compose ps

# Ver logs
docker-compose logs -f

# Probar health check
curl http://localhost:3008/health
```

## 🔧 Configuración de Webhooks

### Para Desarrollo Local (con ngrok)

1. **Instalar ngrok**
2. **Exponer puerto local:**
   ```bash
   ngrok http 3008
   ```
3. **Configurar webhook en Meta:**
   - URL: `https://tu-dominio-ngrok.ngrok.io/webhook`
   - Verify Token: El valor de `VERIFY_TOKEN` en tu .env

### Para Producción

1. **Configurar dominio y SSL**
2. **Configurar webhook en Meta:**
   - URL: `https://tu-dominio.com/webhook`
   - Verify Token: El valor de `VERIFY_TOKEN` en tu .env

## 🌐 Comunicación con Proyecto IPS

### Red Compartida

Ambos proyectos se comunican a través de la red Docker `shared_network`:

```yaml
# En docker-compose.yml
networks:
  shared_network:
    external: true
    name: shared_network
```

### URLs de Comunicación Interna

- **Bot → Backend IPS**: `http://backend:8000/api`
- **Backend IPS → Bot**: `http://bot-meta:3008`

## 📊 Monitoreo y Mantenimiento

### Endpoints Útiles

- **Health Check**: `GET /health`
- **Info del Bot**: `GET /bot/info`
- **Enviar Mensaje**: `POST /v1/messages`
- **Gestión Blacklist**: `POST /v1/blacklist`

### Comandos de Mantenimiento

```bash
# Ver logs en tiempo real
docker-compose logs -f bot-meta

# Reiniciar servicio
docker-compose restart bot-meta

# Actualizar aplicación
git pull
docker-compose build --no-cache
docker-compose up -d

# Backup de configuración
cp .env .env.backup.$(date +%Y%m%d)
```

### Logs Importantes

Los logs incluyen:
- Conexiones de usuarios
- Mensajes enviados/recibidos
- Errores de integración con APIs
- Métricas de uso

## 🚨 Solución de Problemas

### Problema: Contenedor no inicia

```bash
# Verificar logs
docker-compose logs bot-meta

# Verificar configuración
docker-compose config

# Reconstruir imagen
docker-compose build --no-cache bot-meta
```

### Problema: No recibe webhooks

1. **Verificar configuración de webhook en Meta**
2. **Verificar conectividad externa:**
   ```bash
   curl -X GET "https://tu-dominio.com/webhook?hub.verify_token=tu_verify_token&hub.challenge=test&hub.mode=subscribe"
   ```
3. **Verificar logs del bot**

### Problema: No se comunica con Backend IPS

1. **Verificar red compartida:**
   ```bash
   docker network inspect shared_network
   ```
2. **Verificar conectividad:**
   ```bash
   docker-compose exec bot-meta ping backend
   ```
3. **Verificar URL de backend en .env**

## 📁 Estructura de Archivos

```
bot-meta-plantilla/
├── bot-meta/
│   ├── src/
│   ├── assets/
│   ├── Dockerfile
│   └── package.json
├── docker-compose.yml
├── .env
├── .env.example
├── deploy.sh
├── deploy.ps1
├── setup-shared-network.sh
└── README_DEPLOYMENT.md
```

## 🔐 Seguridad

### Buenas Prácticas

1. **No versionar .env** - Ya está en .gitignore
2. **Usar tokens seguros** - Cambiar valores por defecto
3. **Usuario no-root** - Ya configurado en Dockerfile
4. **Limitar puertos** - Solo exponer los necesarios
5. **Monitorear logs** - Revisar accesos no autorizados

### Variables Sensibles

```bash
# Estas variables NUNCA deben versionarse
JWT_TOKEN=tu_token_secreto
API_KEY_SHEETBEST=tu_api_key_secreta
VERIFY_TOKEN=tu_token_verificacion
```

## 📞 Soporte

Para problemas o dudas:

1. **Revisar logs**: `docker-compose logs -f`
2. **Verificar configuración**: `docker-compose config`
3. **Probar health checks**: `curl http://localhost:3008/health`
4. **Revisar documentación de Meta WhatsApp Business API**

---

*Actualizado: Julio 2025*
