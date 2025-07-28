# Multi-stage build optimizado para producción
# Imagen base ~400MB final
FROM node:21-alpine3.18 as builder

WORKDIR /app

# Configurar variables de entorno para build
ENV NODE_ENV=production

# Copiar archivos de configuración primero para aprovechar cache de Docker
COPY package*.json ./
COPY tsconfig*.json rollup.config.js jest.config.js ./

# Instalar dependencias de sistema necesarias para build
RUN apk add --no-cache --virtual .build-deps \
        python3 \
        make \
        g++ \
        git \
    && apk add --no-cache \
        curl \
        dumb-init

# Instalar dependencias (incluye devDependencies para build)
RUN npm install

# Copiar código fuente
COPY src/ ./src/
COPY assets/ ./assets/

# Compilar aplicación TypeScript
RUN npm run build

# Limpiar dependencias de build
RUN apk del .build-deps

# ===============================================
# Etapa de producción optimizada
# ===============================================
FROM node:21-alpine3.18 as production

WORKDIR /app

# Variables de entorno para producción
ENV NODE_ENV=production
ENV PORT=3008

# Instalar solo las herramientas necesarias para runtime
RUN apk add --no-cache \
        curl \
        dumb-init \
        tini

# Crear usuario no-root con ID específico
RUN addgroup -g 1001 -S nodejs \
    && adduser -S -u 1001 -G nodejs nodejs

# Copiar archivos de dependencias desde builder
COPY --from=builder --chown=nodejs:nodejs /app/package*.json ./

# Instalar SOLO dependencias de producción
RUN npm install --only=production --ignore-scripts \
    && npm cache clean --force

# Copiar archivos compilados y assets
COPY --from=builder --chown=nodejs:nodejs /app/dist ./dist
COPY --from=builder --chown=nodejs:nodejs /app/assets ./assets

# Copiar health check script
COPY --chown=nodejs:nodejs healthcheck.js ./

# Crear directorios necesarios con permisos correctos
RUN mkdir -p /app/logs /app/tmp \
    && chown -R nodejs:nodejs /app

# Cambiar a usuario no-root
USER nodejs

# Exponer puerto
EXPOSE $PORT

# Health check optimizado
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
    CMD node /app/healthcheck.js || exit 1

# Usar tini como init system para manejo correcto de señales
ENTRYPOINT ["/sbin/tini", "--"]

# Comando por defecto
CMD ["node", "./dist/app.js"]