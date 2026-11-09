const { test } = require('node:test');
const assert = require('node:assert/strict');
const jwt = require('jsonwebtoken');

// Exercise the real Express routes and bcrypt/JWT code without a live database.
process.env.JWT_SECRET = 'test-only-secret-never-use-in-production';
delete process.env.JWT_EXPIRES_IN;
const users = [];
const dbPath = require.resolve('../src/config/db');
require.cache[dbPath] = { id: dbPath, filename: dbPath, loaded: true, exports: {
  query: async (sql, values) => {
    if (/insert into users/i.test(sql)) {
      if (users.some(u => u.email === values[1].toLowerCase())) {
        throw Object.assign(new Error('duplicate'), { code: '23505' });
      }
      const user = { id: String(users.length + 1), name: values[0], email: values[1].toLowerCase(), password_hash: values[2], role: values[3] };
      users.push(user);
      const { password_hash, ...publicUser } = user;
      return { rows: [publicUser] };
    }
    const user = /WHERE email/i.test(sql)
      ? users.find(u => u.email === values[0])
      : users.find(u => u.id === values[0]);
    if (!user) return { rows: [] };
    if (/WHERE email/i.test(sql)) return { rows: [{ ...user }] };
    const { password_hash, ...publicUser } = user;
    return { rows: [publicUser] };
  },
}};
const app = require('../src/app');

test('register, login, authenticated profile, rejection and expiry contract', async () => {
  const server = app.listen(0, '127.0.0.1');
  await new Promise(resolve => server.once('listening', resolve));
  const base = `http://127.0.0.1:${server.address().port}/api/auth`;
  const post = (path, body) => fetch(`${base}/${path}`, {
    method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body),
  });
  try {
    const account = { name: 'Test Student', email: 'student@example.com', password: 'secret123', role: 'student' };
    const registered = await post('register', account);
    assert.equal(registered.status, 201);
    const session = await registered.json();
    assert.ok(session.token); assert.equal(session.user.password_hash, undefined);
    assert.notEqual(users[0].password_hash, account.password);
    assert.equal((await post('register', account)).status, 409);
    assert.equal((await post('login', { email: account.email, password: 'wrong' })).status, 401);
    const loggedIn = await post('login', { email: ' STUDENT@EXAMPLE.COM ', password: account.password });
    assert.equal(loggedIn.status, 200);
    const { token } = await loggedIn.json();
    const claims = jwt.verify(token, process.env.JWT_SECRET);
    assert.equal(claims.exp - claims.iat, 7 * 24 * 60 * 60);
    const me = await fetch(`${base}/me`, { headers: { Authorization: `Bearer ${token}` } });
    assert.equal(me.status, 200); assert.equal((await me.json()).user.email, account.email);
    assert.equal((await fetch(`${base}/me`)).status, 401);
    const expired = jwt.sign({ id: session.user.id }, process.env.JWT_SECRET, { expiresIn: -1 });
    assert.equal((await fetch(`${base}/me`, { headers: { Authorization: `Bearer ${expired}` } })).status, 401);
  } finally { await new Promise(resolve => server.close(resolve)); }
});
