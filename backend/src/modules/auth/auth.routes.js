const router = require('express').Router();
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const db = require('../../config/db');
const { requireAuth, requireRole } = require('../../middleware/auth');


router.post('/register', async (req, res) => {
  const { name, email, password, phone, role = 'student' } = req.body;

  if (
  typeof name !== 'string' ||
  !name.trim() ||
  typeof email !== 'string' ||
  !email.trim() ||
  typeof password !== 'string' ||
  password.length < 6
  ) {
    return res.status(400).json({ message: 'name, email and password (min 6 chars) are required' });
  }
  if (!['student', 'shop_owner'].includes(role)) {
    return res.status(400).json({ message: 'Invalid role' });
  }

  try {
    const passwordHash = await bcrypt.hash(password, 10);

    const { rows } = await db.query(
      `insert into users (name, email, password_hash, role, phone)
       values ($1, lower($2), $3, $4, $5)
       returning id, name, email, role`,
      [name.trim(), email, passwordHash, role, phone?.trim() || null]
    );
    const user = rows[0];

    const token = jwt.sign(
      { id: user.id, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
    );

    res.status(201).json({ token, user });
  } catch (err) {
    if (err.code === '23505') {
      return res.status(409).json({ message: 'Email already registered' });
    }
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});


router.post('/login', async (req, res) => {
  try {
    const { password } = req.body;
    const email =
      typeof req.body.email === 'string'
        ? req.body.email.toLowerCase().trim()
        : '';

    if (!email || !password) {
      return res.status(400).json({ message: 'Email and password are required' });
    }

    const result = await db.query(
      'SELECT id, name, email, password_hash, role, phone FROM users WHERE email = $1',
      [email.toLowerCase().trim()]
    );

    const user = result.rows[0];

    const passwordOk = user
      ? await bcrypt.compare(password, user.password_hash)
      : false;

    if (!user || !passwordOk) {
      return res.status(401).json({ message: 'Invalid email or password' });
    }

    const token = jwt.sign(
      { id: user.id, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
    );

    delete user.password_hash;
    res.json({ token, user });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});


router.get('/me', requireAuth, async (req, res) => {
  try {
    const result = await db.query(
      'SELECT id, name, email, role, phone, created_at FROM users WHERE id = $1',
      [req.user.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'User not found' });
    }

    res.json({ user: result.rows[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;
