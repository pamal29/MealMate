const router = require('express').Router();
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const db = require('../../config/db');

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

module.exports = router;