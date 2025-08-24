
import { Router } from 'express';
import { z } from 'zod';
import { pool } from './db';

export const router = Router();

router.get('/items', async (_req, res) => {
  try {
    const { rows } = await pool.query('SELECT id, name FROM items ORDER BY id ASC');
    res.json(rows);
  } catch (err) {
    reqLog(err);
    res.status(500).json({ error: 'DB error' });
  }
});
router.get('/db/ping', async (_req, res) => {
  try {
    const { rows } = await pool.query('select now() as now');
    res.json({ ok: true, now: rows[0].now });
  } catch (e) {
    console.error('db ping failed:', e);
    res.status(500).json({ ok: false });
  }
});

router.post('/items', async (req, res) => {
  const schema = z.object({ name: z.string().min(1).max(200) });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: 'Invalid body' });
  try {
    const { rows } = await pool.query('INSERT INTO items(name) VALUES($1) RETURNING id, name', [parsed.data.name]);
    res.status(201).json(rows[0]);
  } catch (err) {
    reqLog(err);
    res.status(500).json({ error: 'DB error' });
  }
});

function reqLog(err: unknown) {
  // minimal safe logging
  // eslint-disable-next-line no-console
  console.error('[route-error]', err);
}
