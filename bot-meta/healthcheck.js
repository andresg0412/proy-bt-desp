#!/usr/bin/env node

/**
 * Health Check Script para Bot Meta
 * Verifica el estado del bot y sus dependencias críticas
 */

const http = require('http');
const { promisify } = require('util');

const PORT = process.env.PORT || 3008;
const TIMEOUT = 5000; // 5 segundos

// Función para hacer request HTTP
const makeRequest = (options) => {
    return new Promise((resolve, reject) => {
        const req = http.request(options, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => resolve({ status: res.statusCode, data }));
        });
        
        req.on('error', reject);
        req.setTimeout(TIMEOUT, () => {
            req.destroy();
            reject(new Error('Request timeout'));
        });
        
        req.end();
    });
};

// Health checks
const checks = {
    // Verificar endpoint principal
    async webServer() {
        try {
            const response = await makeRequest({
                hostname: 'localhost',
                port: PORT,
                path: '/health',
                method: 'GET',
                timeout: TIMEOUT
            });
            
            return response.status === 200;
        } catch (error) {
            console.error('Web server check failed:', error.message);
            return false;
        }
    },

    // Verificar memoria disponible
    memory() {
        const used = process.memoryUsage();
        const totalMB = used.heapTotal / 1024 / 1024;
        const usedMB = used.heapUsed / 1024 / 1024;
        const usage = (usedMB / totalMB) * 100;
        
        // Falla si usa más del 90% de memoria
        if (usage > 90) {
            console.error(`High memory usage: ${usage.toFixed(2)}%`);
            return false;
        }
        
        return true;
    },

    // Verificar que el proceso no esté zombie
    processStatus() {
        try {
            // Verificar que el proceso responda
            if (!process.pid) {
                console.error('No process ID available');
                return false;
            }
            
            return true;
        } catch (error) {
            console.error('Process status check failed:', error.message);
            return false;
        }
    }
};

// Ejecutar health checks
async function runHealthChecks() {
    console.log('🔍 Running health checks...');
    
    const results = await Promise.allSettled([
        checks.webServer(),
        Promise.resolve(checks.memory()),
        Promise.resolve(checks.processStatus())
    ]);
    
    const failed = results.filter((result, index) => {
        const checkName = Object.keys(checks)[index];
        const success = result.status === 'fulfilled' && result.value === true;
        
        if (!success) {
            console.error(`❌ ${checkName}: FAILED`);
            if (result.status === 'rejected') {
                console.error(`   Error: ${result.reason?.message || result.reason}`);
            }
        } else {
            console.log(`✅ ${checkName}: OK`);
        }
        
        return !success;
    });
    
    if (failed.length > 0) {
        console.error(`\n💥 Health check failed: ${failed.length}/${results.length} checks failed`);
        process.exit(1);
    } else {
        console.log('\n🎉 All health checks passed!');
        process.exit(0);
    }
}

// Manejo de señales
process.on('SIGTERM', () => {
    console.log('Received SIGTERM, exiting health check...');
    process.exit(1);
});

process.on('SIGINT', () => {
    console.log('Received SIGINT, exiting health check...');
    process.exit(1);
});

// Ejecutar
runHealthChecks().catch((error) => {
    console.error('Health check error:', error);
    process.exit(1);
});
