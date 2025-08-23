
import { Pool } from 'pg';

const required = (k: string) => {
  const v = process.env[k];
  if (!v) throw new Error(`Missing env: ${k}`);
  return v;
};

const DB_HOST = required('DB_HOST');
const DB_PORT = Number(process.env.DB_PORT || '5432');
const DB_NAME = required('DB_NAME');
const DB_USER = required('DB_USER');
const DB_PASSWORD = required('DB_PASSWORD');

export const pool = new Pool({
  host: DB_HOST,
  port: DB_PORT,
  database: DB_NAME,
  user: DB_USER,
  password: DB_PASSWORD,
  ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : false,
  max: 5,
  idleTimeoutMillis: 30_000,
  connectionTimeoutMillis: 10_000,
});
