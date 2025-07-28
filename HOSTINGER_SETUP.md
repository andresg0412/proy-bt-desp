# Configuración con Dominio Propio de Hostinger

## PASO 1: Configurar Subdomain en Hostinger

### En Panel de Hostinger:
1. **Domains** → **Subdomains**
2. **Create Subdomain**: `bot` (o `whatsapp`)
3. **Domain**: Selecciona tu dominio principal
4. **Document Root**: Dejar por defecto
5. **Create**

### Configurar DNS:
1. **DNS Zone** → **Manage**
2. **Add New Record**:
   ```
   Type: A
   Name: bot
   Points to: [IP_DE_TU_SERVIDOR_DIGITALOCEAN]
   TTL: 3600
   ```
3. **Add Record**

## PASO 2: Configurar en Servidor DigitalOcean

### Conectar al servidor:
```bash
ssh root@tu-ip-servidor
cd /opt/proyectos/bot-meta-plantilla
```

### Actualizar configuración del bot:
```bash
# Editar .env
nano .env
```

**Cambiar estas líneas:**
```bash
# Dominio público para webhooks
PUBLIC_DOMAIN=bot.tu-dominio.com
WEBHOOK_URL=https://bot.tu-dominio.com/webhook
```

### Actualizar configuración de Nginx:
```bash
# Editar configuración de Nginx
nano nginx/conf.d/bot-meta.conf
```

**Cambiar:**
```nginx
server {
    listen 80;
    server_name bot.tu-dominio.com;  # ← Cambiar aquí
    
    # Resto de configuración igual...
}
```

## PASO 3: Configurar SSL

### Instalar Certbot:
```bash
sudo apt update
sudo apt install certbot python3-certbot-nginx
```

### Obtener certificado SSL:
```bash
# Parar Nginx temporalmente
docker-compose stop nginx

# Obtener certificado
sudo certbot certonly --standalone -d bot.tu-dominio.com

# Los certificados se guardan en:
# /etc/letsencrypt/live/bot.tu-dominio.com/
```

### Configurar SSL en Nginx:
```bash
# Copiar certificados a directorio de nginx
sudo cp /etc/letsencrypt/live/bot.tu-dominio.com/fullchain.pem nginx/ssl/cert.pem
sudo cp /etc/letsencrypt/live/bot.tu-dominio.com/privkey.pem nginx/ssl/key.pem

# Cambiar permisos
sudo chown $USER:$USER nginx/ssl/*
```

### Activar HTTPS en Nginx:
```bash
nano nginx/conf.d/bot-meta.conf
```

**Descomentar y configurar la sección HTTPS:**
```nginx
# Descomentar esta sección y configurar:
server {
    listen 443 ssl http2;
    server_name bot.tu-dominio.com;  # ← Tu dominio
    
    ssl_certificate /etc/nginx/ssl/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/key.pem;
    
    # Resto de configuración igual que HTTP...
}

# Agregar redirección HTTP → HTTPS:
server {
    listen 80;
    server_name bot.tu-dominio.com;
    return 301 https://$server_name$request_uri;
}
```

## PASO 4: Reiniciar y Probar

### Reiniciar servicios:
```bash
docker-compose down
docker-compose up -d
```

### Verificar funcionamiento:
```bash
# Probar HTTP (debe redirigir a HTTPS)
curl -I http://bot.tu-dominio.com/health

# Probar HTTPS
curl https://bot.tu-dominio.com/health

# Probar webhook verification
curl -X GET "https://bot.tu-dominio.com/webhook?hub.verify_token=palabrasecreta&hub.challenge=test&hub.mode=subscribe"
```

## PASO 5: Configurar en Meta

### En Meta Developer Console:
1. **WhatsApp** → **Configuration**
2. **Webhook URL**: `https://bot.tu-dominio.com/webhook`
3. **Verify Token**: `palabrasecreta` (el de tu .env)
4. **Verify and Save**
5. **Subscribe** a eventos: `messages`, `messaging_postbacks`

## PASO 6: Automatizar Renovación SSL

### Crear script de renovación:
```bash
cat > /opt/scripts/renew-ssl.sh << 'EOF'
#!/bin/bash
# Script para renovar SSL y actualizar certificados

# Parar nginx
cd /opt/proyectos/bot-meta-plantilla
docker-compose stop nginx

# Renovar certificado
certbot renew --quiet

# Copiar certificados actualizados
cp /etc/letsencrypt/live/bot.tu-dominio.com/fullchain.pem nginx/ssl/cert.pem
cp /etc/letsencrypt/live/bot.tu-dominio.com/privkey.pem nginx/ssl/key.pem

# Cambiar permisos
chown $USER:$USER nginx/ssl/*

# Reiniciar nginx
docker-compose start nginx

echo "SSL renovado exitosamente: $(date)"
EOF

chmod +x /opt/scripts/renew-ssl.sh
```

### Configurar cron:
```bash
sudo crontab -e
```

**Agregar:**
```bash
# Renovar SSL cada día a las 2 AM
0 2 * * * /opt/scripts/renew-ssl.sh >> /var/log/ssl-renewal.log 2>&1
```

## Verificación Final

```bash
# Ver logs del bot
docker-compose logs -f

# Ver estado de servicios
docker-compose ps

# Probar con curl
curl -X POST https://bot.tu-dominio.com/v1/messages \
  -H "Content-Type: application/json" \
  -d '{"number":"test","message":"test"}'
```

---

**¡Tu bot estará disponible en: `https://bot.tu-dominio.com/webhook`**
