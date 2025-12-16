// ============================================
// CORDLY Backend - Entry Point
// ============================================
import 'dotenv/config';
import express, { Request, Response, NextFunction, ErrorRequestHandler } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import { createClient, SupabaseClient } from '@supabase/supabase-js';

// ----------------------
// Configuration Validation
// ----------------------
const requiredEnvVars = ['SUPABASE_URL', 'SUPABASE_SERVICE_ROLE_KEY'];
const missingVars = requiredEnvVars.filter((v) => !process.env[v]);
if (missingVars.length > 0 && process.env.NODE_ENV === 'production') {
    console.error(`❌ Missing required environment variables: ${missingVars.join(', ')}`);
    process.exit(1);
}

// ----------------------
// Supabase Client (Service Role - Backend Only)
// ----------------------
let supabase: SupabaseClient | null = null;
if (process.env.SUPABASE_URL && process.env.SUPABASE_SERVICE_ROLE_KEY) {
    supabase = createClient(
        process.env.SUPABASE_URL,
        process.env.SUPABASE_SERVICE_ROLE_KEY,
        {
            auth: {
                autoRefreshToken: false,
                persistSession: false,
            },
        }
    );
}

// Export for use in routes
export { supabase };

// ----------------------
// Express App
// ----------------------
const app = express();
const PORT = process.env.PORT || 3000;

// ----------------------
// Security Middleware
// ----------------------
app.use(helmet());
app.use(cors({
    origin: process.env.CORS_ORIGIN || '*',
    credentials: true,
}));
app.use(express.json({ limit: '1mb' }));

// ----------------------
// Request Logging (Simple)
// ----------------------
app.use((req: Request, _res: Response, next: NextFunction) => {
    const timestamp = new Date().toISOString();
    console.log(`[${timestamp}] ${req.method} ${req.path}`);
    next();
});

// ----------------------
// Global Rate Limiter (Free Tier Protection)
// ----------------------
const globalLimiter = rateLimit({
    windowMs: 60 * 1000, // 1 minute
    max: 100, // 100 requests per minute per IP
    standardHeaders: true,
    legacyHeaders: false,
    message: { error: 'Too many requests. Please slow down.' },
});
app.use(globalLimiter);

// ----------------------
// Async Error Wrapper
// ----------------------
type AsyncHandler = (req: Request, res: Response, next: NextFunction) => Promise<void>;
const asyncHandler = (fn: AsyncHandler) => (req: Request, res: Response, next: NextFunction) => {
    Promise.resolve(fn(req, res, next)).catch(next);
};

// ----------------------
// Health Check
// ----------------------
app.get('/health', asyncHandler(async (_req: Request, res: Response) => {
    const dbStatus = supabase ? 'configured' : 'not configured';
    res.json({
        status: 'ok',
        timestamp: new Date().toISOString(),
        version: '1.0.0',
        database: dbStatus,
    });
}));

// ----------------------
// API Routes
// ----------------------
import workspacesRouter from './routes/workspaces';
import executionsRouter from './routes/executions';
import peopleRouter from './routes/people';
import aiRouter from './routes/ai';

app.use('/api/workspaces', workspacesRouter);
app.use('/api/executions', executionsRouter);
app.use('/api/people', peopleRouter);
app.use('/api/ai', aiRouter);

// Root API info
app.get('/api', (_req: Request, res: Response) => {
    res.json({
        message: 'CORDLY API v1',
        endpoints: {
            health: '/health',
            workspaces: '/api/workspaces',
            executions: '/api/executions',
            people: '/api/people',
            ai: '/api/ai',
        },
    });
});


// ----------------------
// 404 Handler
// ----------------------
app.use((_req: Request, res: Response) => {
    res.status(404).json({ error: 'Not found' });
});

// ----------------------
// Global Error Handler
// ----------------------
const errorHandler: ErrorRequestHandler = (err, _req, res, _next) => {
    console.error('[ERROR]', err.message, err.stack);

    // Don't leak error details in production
    const message = process.env.NODE_ENV === 'production'
        ? 'Internal server error'
        : err.message;

    res.status(500).json({ error: message });
};
app.use(errorHandler);

// ----------------------
// Start Server
// ----------------------
const server = app.listen(PORT, () => {
    console.log(`🚀 CORDLY Backend running on http://localhost:${PORT}`);
    console.log(`   Environment: ${process.env.NODE_ENV || 'development'}`);
    console.log(`   Supabase: ${supabase ? '✓ Connected' : '✗ Not configured'}`);
});

// ----------------------
// Graceful Shutdown
// ----------------------
const shutdown = (signal: string) => {
    console.log(`\n${signal} received. Shutting down gracefully...`);
    server.close(() => {
        console.log('Server closed.');
        process.exit(0);
    });

    // Force close after 10s
    setTimeout(() => {
        console.error('Forced shutdown after timeout.');
        process.exit(1);
    }, 10000);
};

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));
