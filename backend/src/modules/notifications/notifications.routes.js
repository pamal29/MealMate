const express = require('express');
const db = require('../../config/db');
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

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

router.patch('/:id/read', requireAuth, async (req, res) => {
  try {
    const { id } = req.params;
    if (!UUID_RE.test(id)) {
      return res.status(400).json({ message: 'Invalid notification id' });
    }

    const { rows } = await db.query(
      `update notifications
       set is_read = true
       where id = $1 and user_id = $2
       returning id, order_id, type, title, body, is_read, created_at`,
      [id, req.user.id]
    );

    if (rows.length === 0) {
      return res.status(404).json({ message: 'Notification not found' });
    }
    return res.json({ notification: rows[0] });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;