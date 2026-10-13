const router = require('express').Router();
const db = require('../../config/db');
const {requireAuth}  = require('../../middleware/auth');

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

router.use(requireAuth);

router.get('/', async (req, res) => {
  try{
    const result = await db.query(
      `select id, name, category, location, rating, is_open
      from shops
      order by is_open desc, name asc`
    );
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});

router.get('/:id', async (req, res) => {
  const {id} = req.params;

  if (!UUID_RE.test(id)) {
    return res.status(400).json({ message: 'Invalid shop ID format' });
  }

  try{
    const shop = await db.query(
      `select id, name, category, location, rating, is_open
      from shops
      where id = $1`,
      [id]
    );

    if (shop.rows.length === 0) {
      return res.status(404).json({ message: 'Shop not found' });
    }

    const items = await db.query(
      `select id, name, description, price
      from menu_items
      where shop_id = $1 and is_available = true
      order by name asc`,
      [id]
    );
    res.json({ shop: shop.rows[0], items: items.rows });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;