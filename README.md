# Bot Meta WhatsApp - Configuración Docker para Webhooks

## 🚀 Configuración Completa

Esta configuración permite que Meta WhatsApp Business API envíe webhooks a tu bot mediante Nginx como proxy reverso.

### Estructura Final

```
bot-meta-plantilla/
├── bot-meta/           # Código del bot
├── nginx/              # Configuración de Nginx
│   ├── nginx.conf     # Configuración principal
│   ├── conf.d/
│   │   └── bot-meta.conf  # Configuración del bot
│   └── ssl/           # Certificados SSL (si usas HTTPS)
├── docker-compose.yml  # Orquestación con Nginx
├── .env               # Variables de entorno
└── .env.example       # Plantilla
```

### Cómo Funciona

1. **Meta** envía webhooks → **Nginx (puerto 80/443)** → **Bot Meta (puerto 3008)**
2. **Bot Meta** se comunica con **Backend IPS** a través de la red compartida Docker
3. **Nginx** maneja SSL, logs y balanceo si es necesario

## 📝 Pasos de Configuración

### 1. Variables de Entorno

Edita el archivo `.env`:

```bash
# Configuración del bot
BOT_PORT=3008
NODE_ENV=production

# Meta WhatsApp Business API
JWT_TOKEN=tu_token_real
NUMBER_ID=tu_number_id
VERIFY_TOKEN=tu_verify_token

# APIs externas
URL_SHEETBEST=https://api.sheetbest.com/sheets/tu_sheet_id
API_KEY_SHEETBEST=tu_api_key

# Integración con Backend IPS
API_BACKEND_URL=http://backend:8000/api

# Red compartida
EXTERNAL_NETWORK_NAME=shared_network

# Dominio público para webhooks
PUBLIC_DOMAIN=tu-dominio.com
WEBHOOK_URL=https://tu-dominio.com/webhook
```

### 2. Configuración de Dominio (REQUERIDO para Meta)

**⚠️ IMPORTANTE**: Meta NO acepta IPs directas como `https://90.25.253.1/webhook`. Necesitas un dominio real.

**Opción A: Desarrollo/Testing - ngrok (Gratuito)**
```bash
# Instalar ngrok
npm install -g ngrok

# Registrarse en ngrok.com y obtener authtoken
ngrok config add-authtoken TU_TOKEN

# Exponer puerto 80
ngrok http 80 --domain=tu-bot.ngrok.io

# Usar URL: https://tu-bot.ngrok.io/webhook
```

**Opción B: Producción - Dominio gratuito + Cloudflare**
```bash
# 1. Obtener dominio gratis en freenom.com (.tk, .ml, .ga, .cf)
# 2. Configurar DNS en cloudflare.com
# 3. Usar Cloudflare Tunnel:
cloudflared tunnel --url http://localhost:80

# URL final: https://tu-dominio.tk/webhook
```

**Opción C: Rápida - Serveo**
```bash
# Solo un comando
ssh -R 80:localhost:80 serveo.net
# Te da: https://random.serveo.net/webhook
```

Ver archivos `NGROK_SETUP.md` y `DOMAIN_SETUP.md` para instrucciones detalladas.

### 3. Configurar Webhook en Meta

En Meta Developer Console:
1. Ve a tu aplicación WhatsApp Business
2. Configura webhook:
   - **URL**: `https://tu-dominio.com/webhook`
   - **Verify Token**: El valor de `VERIFY_TOKEN` de tu .env
3. Suscríbete a eventos: `messages`, `messaging_postbacks`

### 4. Desplegar

```bash
# Crear red compartida si no existe
docker network create shared_network

# Levantar servicios
docker-compose up -d

# Verificar estado
docker-compose ps

# Ver logs
docker-compose logs -f
```

## 🔧 Endpoints Importantes

- **Webhook**: `https://tu-dominio.com/webhook` (Meta envía aquí)
- **Health Check**: `http://tu-dominio.com/health`
- **Info del Bot**: `http://tu-dominio.com/bot/info`
- **APIs del Bot**: `http://tu-dominio.com/v1/*`

## 🌐 Comunicación entre Proyectos

### Red Docker Compartida

Ambos proyectos usan `shared_network`:

```yaml
networks:
  shared_network:
    external: true
    name: shared_network
```

### URLs Internas

- **Bot → Backend IPS**: `http://backend:8000/api`
- **Backend IPS → Bot**: `http://bot-meta:3008`
- **Nginx → Bot**: `http://bot-meta:3008`

## 🔒 SSL/HTTPS (Recomendado para Producción)

### Con Let's Encrypt

```bash
# Instalar certbot
sudo apt install certbot python3-certbot-nginx

# Obtener certificado
sudo certbot --nginx -d tu-dominio.com

# Los certificados se instalan automáticamente en Nginx
```

### Configuración Manual SSL

1. Coloca certificados en `nginx/ssl/`
2. Descomenta la sección HTTPS en `nginx/conf.d/bot-meta.conf`
3. Actualiza `server_name` con tu dominio real

## 🚨 Solución de Problemas

### Bot no recibe webhooks

```bash
# Verificar que Nginx esté funcionando
curl http://localhost/health

# Verificar logs de webhook
docker-compose logs nginx | grep webhook

# Probar verificación de webhook manualmente
curl -X GET "http://localhost/webhook?hub.verify_token=tu_verify_token&hub.challenge=test&hub.mode=subscribe"
```

### Problemas de red

```bash
# Verificar red compartida
docker network inspect shared_network

# Verificar conectividad interna
docker-compose exec nginx ping bot-meta
docker-compose exec bot-meta ping backend
```

## 📊 Monitoreo

```bash
# Logs en tiempo real
docker-compose logs -f

# Logs solo del bot
docker-compose logs -f bot-meta

# Logs solo de Nginx
docker-compose logs -f nginx

# Estado de servicios
docker-compose ps
```

---

**Nota**: Esta configuración permite que Meta envíe webhooks directamente a tu bot a través de Nginx, manteniendo la comunicación interna con el proyecto IPS funcionando correctamente.
