const router = require('express').Router();
const db = require('../../config/db');
const {requireAuth, requireRole} = require ('../../middleware/auth');

router.use(requireAuth, requireRole('shop_owner'));

router.post('/', async (req, res) => {
  const { name, category, location } = req.body;

  if(!name || !category || !location) {
    return res.status(400).json({ error: 'All fields are required' });
  }

  try {
    const result = await db.query(
      `INSERT INTO shops (owner_id, name, category, location) 
      VALUES ($1, $2, $3, $4)
      returning *`,
      [req.user.id, name.trim(), category.trim(), location.trim()]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    if (err.code === '23505') {
      return res.status(400).json({ error: 'Shop with this name already exists' });
    }
    console.error(err);
    res.status(500).json({ error: 'Internal server error' });
  }
});


router.get('/mine', async (req, res) => {
  try {
    const result = await db.query(
      'select * from shops where owner_id = $1',
      [req.user.id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'You have not created a shop yet' });
    }
    res.json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;
