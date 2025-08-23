
import express from 'express';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import pinoHttp from 'pino-http';
import { router as api } from './routes';

const app = express();

app.use(express.json());
app.use(helmet());
app.use(rateLimit({ windowMs: 60_000, max: 120 }));
app.use(pinoHttp());

app.get('/healthz', (_req, res) => res.json({ status: 'ok' }));
app.use('/api/v1', api);

// Catch-all
app.use((_req, res) => res.status(404).json({ error: 'Not found' }));

const port = process.env.PORT ? Number(process.env.PORT) : 8080;
app.listen(port, () => {
  /* eslint-disable no-console */
  console.log(`Server listening on :${port}`);
});
