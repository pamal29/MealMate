const express = require('express');
const db = require('../../db');
const { requireAuth } = require('../../middleware/auth');

const router = express.Router();

router.get('/', requireAuth, async (req, res) => {
  try {
    const { rows } = await db.query(
      `select id, order_id, type, title, body, is_read, created_at
       from notifications
       where user_id = $1
       order by created_at desc
       limit 50`,
      [req.user.id]
    );
    return res.json({ notifications: rows });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;