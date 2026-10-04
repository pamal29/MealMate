require('dotenv').config();
const { Client } = require('pg');

const client = new Client({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false, minVersion: 'TLSv1.2' },
});

client.connect()
  .then(() => client.query('select now()'))
  .then((r) => { console.log('OK', r.rows[0]); return client.end(); })
  .catch((e) => { console.error('FAIL', e.code, e.message); process.exit(1); });