// test-db.js
require('dotenv').config();
const db = require('./src/config/db');   // adjust path
db.query('select now()')
  .then(r => { console.log('OK', r.rows[0]); process.exit(0); })
  .catch(e => { console.error('FAIL', e.message); process.exit(1); });