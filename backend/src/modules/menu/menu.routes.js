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

// UUID check, so a bad :id gives 400 instead of a database error
const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

//edit menu item
router.put('./:id', async (req, res) => {
  const {id} = req.params;
  const {name, description, price, is_available} = req.body;

  if (!UUID_RE.test(id)) {
    return res.status(400).json({ message: 'Invalid item ID format' });
  }

  if(is_available !== undefined && typeof is_available !== 'boolean'){
    return res.status(400).json({ message: 'is_available must be a boolean' });
  }

  let priceNum = null;
  if (price !== undefined) {
    priceNum = Number(price);
    if (Number.isNaN(priceNum) || priceNum < 0) {
      return res.status(400).json({ message: 'Price must be a number, 0 or more' });
    }
  }

  try {
    const result = await db.query(
      ` update menu_items 
        set name = $1, 
            description = $2, 
            price = $3, 
            is_available = $4 
        where id = $5 
          and shop_id(select id from shops where owner_id = $6)
        returning *`,
      [
        name ? name.trim() : null,
        description ? description.trim() : null,
        priceNum,
        is_available ?? null,
        id,
        req.user.id
      ]
    );

    if(result.rows.length === 0 ){
      return res.status(404).json({ message: 'Item not found' });
    }
    res.json(result.rows[0]);
  } catch(err){
    console.error(err);
    res.status(500).json({ message: 'Internal server error' });
  }
});

router.delete('./:id', async (req, res) => {
  const {id} = req.params;

  if (!UUID_RE.test(id)) {
    return res.status(400).json({ message: 'Invalid item ID format' });
  }

  try{
    const result = await db.query(
      `delete from menu_items
      where id = $1
       and shop_id = (select id from shops where owner_id = $2)
       returning id`,
       [id, req.user.id]
    );

    if  (result.rows.length === 0) {
      return res.status(404).json({ message: 'Item not found' });
    }
    res.json({ message: 'Item deleted successfully' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Internal server error' });
  }
});


module.exports = router;