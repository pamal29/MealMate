const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const db = require('./config/db');

const app = express();

app.use(helmet());
app.use(cors());
app.use(express.json());

app.get('/health', (req, res) => {
  res.json({ status: 'ok', service: 'mealmate-api' });
});

app.get('/db-test', async (req, res) => {
  try {
    const { rows } = await db.query('select count(*) from users');
    res.json({ connected: true, users: rows[0].count });
  } catch (err) {
    console.error(err);
    res.status(500).json({ connected: false, error: err.message });
  }
});

app.use((req, res) => {
  res.status(404).json({ message: 'Not found' });
});

module.exports = app;