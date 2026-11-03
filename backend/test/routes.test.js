const { test } = require('node:test');
const assert = require('node:assert/strict');
const jwt = require('jsonwebtoken');

// Exercise the real shop and menu routes without a live database.
process.env.JWT_SECRET = 'test-only-secret-never-use-in-production';
const SHOP_ID = '11111111-1111-4111-8111-111111111111';
const ITEM_ID = '22222222-2222-4222-8222-222222222222';
const shop = { id: SHOP_ID, name: 'Shan Food Cabin', category: 'Rice', location: 'Y junction', rating: 4.5, is_open: true };
const queries = [];
const dbPath = require.resolve('../src/config/db');
require.cache[dbPath] = { id: dbPath, filename: dbPath, loaded: true, exports: {
  query: async (sql, values) => {
    queries.push({ sql, values });
    if (/update menu_items/i.test(sql)) return { rows: [{ id: values[4], is_available: values[3] }] };
    if (/delete from menu_items/i.test(sql)) return { rows: [{ id: values[0] }] };
    if (/from menu_items/i.test(sql)) return { rows: [] };
    if (/from shops/i.test(sql)) return { rows: [shop] };
    return { rows: [] };
  },
}};
const app = require('../src/app');

const bearer = (role) =>
  `Bearer ${jwt.sign({ id: 'user-1', role }, process.env.JWT_SECRET)}`;

async function withServer(run) {
  const server = app.listen(0, '127.0.0.1');
  await new Promise(resolve => server.once('listening', resolve));
  try {
    await run(`http://127.0.0.1:${server.address().port}/api`);
  } finally { await new Promise(resolve => server.close(resolve)); }
}

test('students can browse shops without logging in', () => withServer(async (base) => {
  const list = await fetch(`${base}/shops`);
  assert.equal(list.status, 200);
  assert.equal((await list.json())[0].name, 'Shan Food Cabin');

  const details = await fetch(`${base}/shops/${SHOP_ID}`);
  assert.equal(details.status, 200);
  assert.equal((await details.json()).shop.id, SHOP_ID);

  assert.equal((await fetch(`${base}/shops/not-a-uuid`)).status, 400);
}));

test('owners can load their own shop from /shops/mine', () => withServer(async (base) => {
  const mine = await fetch(`${base}/shops/mine`, { headers: { Authorization: bearer('shop_owner') } });
  assert.equal(mine.status, 200);
  assert.equal((await mine.json()).id, SHOP_ID);

  assert.equal((await fetch(`${base}/shops/mine`)).status, 401);
  const asStudent = await fetch(`${base}/shops/mine`, { headers: { Authorization: bearer('student') } });
  assert.equal(asStudent.status, 403);
}));

test('owners can edit a menu item without wiping other fields', () => withServer(async (base) => {
  queries.length = 0;
  const res = await fetch(`${base}/menu/${ITEM_ID}`, {
    method: 'PUT',
    headers: { Authorization: bearer('shop_owner'), 'Content-Type': 'application/json' },
    body: JSON.stringify({ is_available: false }),
  });
  assert.equal(res.status, 200);

  const { sql, values } = queries.find(q => /update menu_items/i.test(q.sql));
  assert.match(sql, /name = coalesce\(\$1, name\)/);
  assert.match(sql, /price = coalesce\(\$3, price\)/);
  assert.match(sql, /shop_id = \(select id from shops where owner_id = \$6\)/);
  assert.deepEqual(values, [null, null, null, false, ITEM_ID, 'user-1']);
}));

test('owners can delete a menu item', () => withServer(async (base) => {
  const res = await fetch(`${base}/menu/${ITEM_ID}`, {
    method: 'DELETE',
    headers: { Authorization: bearer('shop_owner') },
  });
  assert.equal(res.status, 200);
  assert.equal((await res.json()).message, 'Item deleted successfully');
}));
