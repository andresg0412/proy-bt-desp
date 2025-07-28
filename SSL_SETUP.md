# Configuración SSL/HTTPS para Webhooks

## Opción 1: Let's Encrypt (Automático)

```bash
# Instalar certbot
sudo apt update
sudo apt install certbot python3-certbot-nginx

# Obtener certificado para tu dominio
sudo certbot --nginx -d tu-dominio.com

# Verificar renovación automática
sudo crontab -e
# Agregar: 0 12 * * * /usr/bin/certbot renew --quiet
```

## Opción 2: Certificado Manual

### 1. Colocar certificados

```bash
# Copiar certificados a la carpeta SSL
cp tu-certificado.crt nginx/ssl/cert.pem
cp tu-clave-privada.key nginx/ssl/key.pem
```

### 2. Activar HTTPS en Nginx

Editar `nginx/conf.d/bot-meta.conf` y descomentar la sección HTTPS:

```nginx
server {
    listen 443 ssl http2;
    server_name tu-dominio.com;  # Cambiar por tu dominio
    
    ssl_certificate /etc/nginx/ssl/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/key.pem;
    
    # Resto de configuración igual...
}
```

### 3. Redirección HTTP → HTTPS

Agregar al final de `nginx/conf.d/bot-meta.conf`:

```nginx
# Redirección HTTP a HTTPS
server {
    listen 80;
    server_name tu-dominio.com;
    return 301 https://$server_name$request_uri;
}
```

## Opción 3: Desarrollo Local con ngrok

```bash
# Instalar ngrok
curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null
echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | sudo tee /etc/apt/sources.list.d/ngrok.list
sudo apt update && sudo apt install ngrok

# Configurar token (registro en ngrok.com)
ngrok config add-authtoken TU_TOKEN_NGROK

# Exponer puerto 80 con dominio estático
ngrok http 80 --domain=tu-subdominio.ngrok.io
```

## Verificar SSL

```bash
# Probar certificado
openssl s_client -connect tu-dominio.com:443 -servername tu-dominio.com

# Verificar webhook con HTTPS
curl -X GET "https://tu-dominio.com/webhook?hub.verify_token=tu_verify_token&hub.challenge=test&hub.mode=subscribe"
```
