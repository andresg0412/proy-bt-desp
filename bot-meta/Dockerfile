# Multi-stage build para optimizar tamaño de imagen final
# Imagen base ~400MB
FROM node:21-alpine3.18 as builder

WORKDIR /app

# Habilitar pnpm
RUN corepack enable && corepack prepare pnpm@latest --activate
ENV PNPM_HOME=/usr/local/bin

# Copiar archivos de configuración primero (cache layers)
COPY package*.json pnpm-lock.yaml ./
COPY tsconfig*.json rollup.config.js ./

# Instalar dependencias de compilación y runtime
RUN apk add --no-cache --virtual .gyp \
        python3 \
        make \
        g++ \
    && apk add --no-cache git curl

# Instalar dependencias
RUN pnpm install

# Copiar código fuente
COPY src/ ./src/
COPY assets/ ./assets/

# Compilar aplicación
RUN pnpm run build && apk del .gyp

# Etapa de producción
FROM node:21-alpine3.18 as deploy

WORKDIR /app

# Argumento para puerto
ARG PORT=3008
ENV PORT=$PORT

# Instalar curl para health checks
RUN apk add --no-cache curl

# Habilitar pnpm en etapa de producción
RUN corepack enable && corepack prepare pnpm@latest --activate 
ENV PNPM_HOME=/usr/local/bin

# Copiar archivos compilados desde builder
COPY --from=builder /app/assets ./assets
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/package*.json /app/pnpm-lock.yaml ./

# Instalar solo dependencias de producción
RUN npm cache clean --force && pnpm install --production --ignore-scripts

# Crear usuario no-root para seguridad
RUN addgroup -g 1001 -S nodejs && adduser -S -u 1001 nodejs

# Cambiar permisos
RUN chown -R nodejs:nodejs /app
USER nodejs

# Exponer puerto
EXPOSE $PORT

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:$PORT/health || exit 1

# Comando por defecto
CMD ["npm", "start"]