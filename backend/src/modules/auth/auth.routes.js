const express = require('express');
const router = require('express').Router();
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const db = require('../../config/db');
const { requireAuth } = require('../../middleware/auth');

router.post('/register', async (req, res) => {
  const { name, email, password, role = 'student' } = req.body;

  if (!name || !email || !password || password.length < 6) {
    return res.status(400).json({ message: 'name, email and password (min 6 chars) are required' });
  }
  if (!['student', 'shop_owner'].includes(role)) {
    return res.status(400).json({ message: 'Invalid role' });
  }

  try {
    const passwordHash = await bcrypt.hash(password, 10);

    const { rows } = await db.query(
      `insert into users (name, email, password_hash, role)
       values ($1, lower($2), $3, $4)
       returning id, name, email, role`,
      [name, email, passwordHash, role]
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
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required' });
    }

    const result = await db.query(
      'SELECT id, name, email, password_hash, role FROM users WHERE email = $1',
      [email]
    );

    const user = result.rows[0];

    const passwordOk = user
      ? await bcrypt.compare(password, user.password_hash)
      : false;

    if (!user || !passwordOk) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    const token = jwt.sign(
      { id: user.id, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN }
    );

    delete user.password_hash;
    res.json({ token, user });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});


router.get('/me', requireAuth, async (req, res) => {
  try {
    const result = await db.query(
      'SELECT id, name, email, role, created_at FROM users WHERE id = $1',
      [req.user.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json({ user: result.rows[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router;