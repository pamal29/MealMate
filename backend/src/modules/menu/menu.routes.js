const router = require('express').Router();
const db = require('../../config/db');
const { requireAuth, requireRole } = require('../../middleware/auth');

router.use(requireAuth, requireRole('shop_owner')); 

async function getMyShopId(userId){
  const result = await db.query(
    'select id from shops where owner_id = $1',[userId]
  )
  return result.rows.length ? result.rows[0].id : null;
}

router.post('/', async (req, res) => {
  const { name, description, price } = req.body;

  if(!name || price === undefined){
    return res.status(400).json({ message: 'name and price are required' });
  }

  const priceNum = Number(price);
  if (Number.isNaN(priceNum) || priceNum < 0) {
    return res.status(400).json({ message: 'Price must be a number, 0 or more' });
  }

  try {
    const shopId = await getMyShopId(req.user.id);
    if(!shopId){
      return res.status(400).json({ message: 'You must own a shop to add items' });
    }

    const result = await db.query(
      `insert into menu_items (shop_id, name, description, price) 
      values ($1, $2, $3, $4) 
      returning *`,
      [shopId, name.trim(), description? description.trim() : null, priceNum]
    );
    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('Error adding menu item:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});


router.get('/mine', async (req, res) => {
  try {
    const shopId = await getMyShopId(req.user.id);
    if (!shopId) {
      return res.status(404).json({ message: 'Create your shop first' });
    }

    const result = await db.query(
      'select * from menu_items where shop_id = $1 order by created_at desc',
      [shopId]
    );
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;