import express from 'express';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import pinoHttp from 'pino-http';
import { router as api } from './routes';

const app = express();

/**
 * Cloud Run sits behind a proxy; this makes req.ip and rate-limit work correctly.
 */
app.set('trust proxy', true);

/**
 * Core middleware
 */
app.use(express.json());
app.use(helmet());
app.use(
  rateLimit({
    windowMs: 60_000, // 1 minute
    max: 120,         // 120 req/min per client
    standardHeaders: true,
    legacyHeaders: false,
    skip: (req) => req.path === '/healthz', // don't throttle health checks
  })
);
app.use(
  pinoHttp({
    // redact common sensitive headers if they ever appear
    redact: {
      paths: ['req.headers.authorization', 'req.headers.cookie'],
      remove: true,
    },
  })
);

/**
 * Liveness/Readiness
 * Keep these endpoints FAST and side-effect free.
 */
app.get('/', (_req, res) => res.status(200).send('ok'));
app.get('/healthz', (_req,res)=>res.status(200).json({status:'ok'}));

/**
 * API routes
 */
app.use('/api/v1', api);

/**
 * 404 + error handlers
 */
app.use((_req, res) => res.status(404).json({ error: 'Not found' }));

// eslint-disable-next-line @typescript-eslint/no-unused-vars
app.use((err: any, _req: express.Request, res: express.Response, _next: express.NextFunction) => {
  // pino-http adds req.log if you want structured logs:
  // _req.log?.error({ err }, 'unhandled error');
  console.error('unhandled route error:', err);
  res.status(500).json({ error: 'Internal Server Error' });
});
import { Router } from 'express';
import { pool } from '../db';

export const router = Router();

// GET /api/v1/db/ping  ->  { ok: true, now: "..." }
router.get('/db/ping', async (_req, res) => {
  try {
    const { rows } = await pool.query('select now() as now');
    res.json({ ok: true, now: rows[0].now });
  } catch (e) {
    console.error('db ping failed:', e);
    res.status(500).json({ ok: false, error: 'db_unreachable' });
  }
});

/**
 * Start the HTTP listener.
 * Cloud Run injects PORT; DO NOT hardcode or set it yourself in Terraform.
 * Bind to 0.0.0.0 so the container is reachable.
 */
const port = Number(process.env.PORT || 8080);
const host = '0.0.0.0';
const server = app.listen(port, host, () => {
  // eslint-disable-next-line no-console
  console.log(`Server listening on http://${host}:${port}`);
});

/**
 * Be explicit about process-level failures so Cloud Run logs show the cause.
 */
process.on('unhandledRejection', (e) => {
  console.error('unhandledRejection:', e);
  // Let Cloud Run restart the instance
  process.exit(1);
});
process.on('uncaughtException', (e) => {
  console.error('uncaughtException:', e);
  process.exit(1);
});

/**
 * Graceful shutdown (optional but nice)
 */
process.on('SIGTERM', () => {
  console.log('Received SIGTERM, shutting down...');
  server.close(() => {
    console.log('HTTP server closed');
    process.exit(0);
  });
});

export default app;
