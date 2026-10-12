const router = require('express').Router();
const db = require('../../config/db');
const { requireAuth, requireRole } = require('../../middleware/auth');

router.use(requireAuth, requireRole('shop_owner'));

router.post('/', async (req, res) => {
  const { name, category, location } = req.body;

  if (!name || !category || !location) {
    return res.status(400).json({ message: 'name, category and location are required' });
  }

  try {
    const result = await db.query(
      `insert into shops (owner_id, name, category, location)
       values ($1, $2, $3, $4)
       returning *`,
      [req.user.id, name.trim(), category.trim(), location.trim()]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    if (err.code === '23505') {
      return res.status(409).json({ message: 'You already have a shop' });
    }
    console.error(err);
    res.status(500).json({ message: 'Server error' });
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

router.put('/mine', async (req, res) => {
  const { name, category, location, is_open } = req.body;

  if (is_open !== undefined && typeof is_open !== 'boolean') {
    return res.status(400).json({ message: 'is_open must be a boolean' });
  }

  try{
    const result = await db.query(
      // COALESCE() returns the first value that isn't SQL NULL
      
      `update shops
        set name = coalesce($1, name), 
            category = coalesce($2, category),
            location = coalesce($3, location),
            is_open = coalesce($4, is_open)
      where owner_id = $5
      returning *`,
    [
      name? name.trim() : null, 
      category? category.trim() : null, 
      location? location.trim() : null, 
      is_open, 
      req.user.id
    ]
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