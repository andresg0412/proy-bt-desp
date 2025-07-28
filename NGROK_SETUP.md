# Configuración con ngrok (Desarrollo/Testing)

## Instalación de ngrok

### Opción 1: Descarga directa
```bash
# Linux/Mac
curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null
echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | sudo tee /etc/apt/sources.list.d/ngrok.list
sudo apt update && sudo apt install ngrok

# Windows
choco install ngrok
# O descargar desde: https://ngrok.com/download
```

### Opción 2: Con npm
```bash
npm install -g ngrok
```

## Configuración

### 1. Crear cuenta gratuita en ngrok.com
- Ve a https://ngrok.com/signup
- Copia tu authtoken

### 2. Configurar token
```bash
ngrok config add-authtoken TU_TOKEN_AQUI
```

### 3. Exponer tu bot
```bash
# Básico (URL aleatoria)
ngrok http 80

# Con subdominio fijo (requiere cuenta)
ngrok http 80 --domain=tu-bot-whatsapp.ngrok.io
```

### 4. Configurar webhook en Meta
- URL: `https://abc123.ngrok.io/webhook`
- Verify Token: El de tu archivo .env

## Automatización

### Script para auto-start
```bash
#!/bin/bash
# start-bot.sh

# Iniciar servicios Docker
docker-compose up -d

# Esperar que estén listos
sleep 10

# Iniciar ngrok
ngrok http 80 --log=stdout --domain=tu-bot-whatsapp.ngrok.io
```

### Con PM2 (mantener corriendo)
```bash
npm install -g pm2

# Crear ecosystem.config.js
cat > ecosystem.config.js << 'EOF'
module.exports = {
  apps: [{
    name: 'ngrok-tunnel',
    script: 'ngrok',
    args: 'http 80 --domain=tu-bot-whatsapp.ngrok.io',
    autorestart: true,
    max_memory_restart: '1G'
  }]
}
EOF

# Iniciar con PM2
pm2 start ecosystem.config.js
pm2 save
pm2 startup
```

## Ventajas Plan Gratuito ngrok

✅ **1 túnel simultáneo**  
✅ **HTTPS automático**  
✅ **40,000 requests/mes**  
✅ **Inspección de tráfico**  
✅ **Subdominio personalizado** (con cuenta)

## Limitaciones

❌ **URL cambia** en cada reinicio (sin cuenta)  
❌ **Límite de ancho de banda**  
❌ **Solo 1 túnel simultáneo**  

## Tips

- **Usar subdominio fijo**: `--domain=tu-nombre.ngrok.io`
- **Logs en tiempo real**: `--log=stdout`
- **Mantener corriendo**: Usar PM2 o systemd
