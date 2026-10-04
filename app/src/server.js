import express from 'express';
import pool from './config/db.js';
import redis from './config/redis.js';

const app = express();
app.use(express.json());

app.get('/health', async (req, res) => {
  await pool.query('SELECT 1');
  await redis.ping();
  res.json({ status: 'ok' });
});

app.listen(3000, () => console.log('app up on 3000'));