const express = require('express');
const db = require('../../config/db');
const { requireAuth, requireRole } = require('../../middleware/auth');

const router = express.Router();

router.use(requireAuth, requireRole('admin'));

router.get('/users', async (req, res) => {
  try {
    const { role } = req.query;
    const allowed = ['student', 'shop_owner', 'admin'];
    if (role !== undefined && !allowed.includes(role)) {
      return res.status(400).json({ message: 'Invalid role filter' });
    }

    const result = await db.query(
      `SELECT id, name, email, role, is_active, created_at
       FROM users
       WHERE ($1::text IS NULL OR role::text = $1)
       ORDER BY created_at DESC
       LIMIT 100`,
      [role ?? null]
    );

    res.json({ users: result.rows });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;