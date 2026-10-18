const express = require('express');
const db = require('../../config/db');
const { requireAuth, requireRole } = require('../../middleware/auth');

const router = express.Router();

const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

router.post('/', requireAuth, requireRole('student'), async (req, res) => {
  try {
    const { shop_id, items, note } = req.body;

    if (typeof shop_id !== 'string' || !UUID_RE.test(shop_id)) {
      return res.status(400).json({ message: 'Valid shop_id is required' });
    }

    if (!Array.isArray(items) || items.length === 0) {
      return res.status(400).json({ message: 'items must be a non-empty array' });
    }

    const seen = new Set();
    for (const it of items) {
      if (
        !it ||
        typeof it.menu_item_id !== 'string' ||
        !UUID_RE.test(it.menu_item_id)
      ) {
        return res.status(400).json({ message: 'Each item needs a valid menu_item_id' });
      }
      if (!Number.isInteger(it.quantity) || it.quantity < 1 || it.quantity > 20) {
        return res.status(400).json({ message: 'quantity must be an integer from 1 to 20' });
      }
      if (seen.has(it.menu_item_id)) {
        return res.status(400).json({ message: 'Duplicate menu_item_id in items' });
      }
      seen.add(it.menu_item_id);
    }

    if (note !== undefined && note !== null && (typeof note !== 'string' || note.length > 200)) {
      return res.status(400).json({ message: 'note must be a string up to 200 characters' });
    }

    const client = await db.connect();
    try {
      await client.query('BEGIN');

      const shopRes = await client.query(
        'SELECT id, is_open FROM shops WHERE id = $1',
        [shop_id]
      );
      if (shopRes.rows.length === 0) {
        await client.query('ROLLBACK');
        return res.status(404).json({ message: 'Shop not found' });
      }
      if (!shopRes.rows[0].is_open) {
        await client.query('ROLLBACK');
        return res.status(409).json({ message: 'Shop is closed' });
      }

      const ids = items.map((i) => i.menu_item_id);
      const menuRes = await client.query(
        `SELECT id, price FROM menu_items
         WHERE id = ANY($1::uuid[]) AND shop_id = $2 AND is_available = true`,
        [ids, shop_id]
      );
      if (menuRes.rows.length !== ids.length) {
        await client.query('ROLLBACK');
        return res
          .status(400)
          .json({ message: 'Some items are unavailable or not from this shop' });
      }

      const priceById = new Map(menuRes.rows.map((r) => [r.id, r.price]));
      let totalCents = 0;
      for (const it of items) {
        const cents = Math.round(parseFloat(priceById.get(it.menu_item_id)) * 100);
        totalCents += cents * it.quantity;
      }
      const total = (totalCents / 100).toFixed(2);

      const orderRes = await client.query(
        `INSERT INTO orders (student_id, shop_id, status, total, note)
         VALUES ($1, $2, 'pending', $3, $4)
         RETURNING id, status, total, pickup_time, note, created_at`,
        [req.user.id, shop_id, total, note ?? null]
      );
      const order = orderRes.rows[0];

      for (const it of items) {
        await client.query(
          `INSERT INTO order_items (order_id, menu_item_id, quantity, unit_price)
           VALUES ($1, $2, $3, $4)`,
          [order.id, it.menu_item_id, it.quantity, priceById.get(it.menu_item_id)]
        );
      }

      await client.query('COMMIT');
      return res.status(201).json({ order });
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});


router.get('/mine', requireAuth, requireRole('student'), async (req, res) => {
  try{
    const result = await db.query(
      `SELECT o.id, o.status, o.total, o.pickup_time, o.note, o.created_at,
              s.id AS shop_id, s.name AS shop_name,
              (SELECT json_agg(
                        json_build_object(
                          'menu_item_id', oi.menu_item_id,
                          'name', mi.name,
                          'quantity', oi.quantity,
                          'unit_price', oi.unit_price
                        ) ORDER BY mi.name)
               FROM order_items oi
               JOIN menu_items mi ON mi.id = oi.menu_item_id
               WHERE oi.order_id = o.id) AS items
       FROM orders o
       JOIN shops s ON s.id = o.shop_id
       WHERE o.student_id = $1
       ORDER BY o.created_at DESC
       LIMIT 50`,
       [req.user.id]
    );
    res.json({orders: result.rows});
  } catch (err){
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});

router.get('/shop', requireAuth, requireRole('shop_owner'), async (req, res) => {
  try {
    const { status } = req.query;
    const allowed = ['pending', 'accepted', 'cancelled'];
    if (status !== undefined && !allowed.includes(status)) {
      return res.status(400).json({ message: 'Invalid status filter' });
    }

    const result = await db.query(
      `SELECT o.id, o.status, o.total, o.pickup_time, o.note, o.created_at,
              u.name AS student_name,
              (SELECT json_agg(
                        json_build_object(
                          'menu_item_id', oi.menu_item_id,
                          'name', mi.name,
                          'quantity', oi.quantity,
                          'unit_price', oi.unit_price
                        ) ORDER BY mi.name)
               FROM order_items oi
               JOIN menu_items mi ON mi.id = oi.menu_item_id
               WHERE oi.order_id = o.id) AS items
       FROM orders o
       JOIN users u ON u.id = o.student_id
       WHERE o.shop_id IN (SELECT id FROM shops WHERE owner_id = $1)
         AND ($2::text IS NULL OR o.status::text = $2)
       ORDER BY o.created_at DESC
       LIMIT 100`,
      [req.user.id, status ?? null]
    );

    res.json({ orders: result.rows });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});

router.patch('/:id/cancel', requireAuth, requireRole('student'), async (req, res) => {
  try{
    const {id} = req.params;
    if(!UUID_RE.test(id)){
      return res.status(400).json({ message: 'Invalid order ID' });
    }

    const result = await db.query(
      `UPDATE orders
       SET status = 'cancelled'
       WHERE id = $1
        AND student_id = $2
        AND status = 'pending'
      RETURNING id, status, total, pickup_time, note, created_at`,
      [id, req.user.id]
    )

    if(result.rows.length === 0){
      return res.status(404).json({ message: 'Order not found or already cancelled' });
    }
    res.json({ order: result.rows[0] });
  } catch (err){
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});


//business owner side
router.get('/shop', requireAuth, requireRole('shop_owner'), async (req, res) => {
  try{
    const {status} = req.query;
    const allowed = ['pending', 'accepted', 'rejected'];
    if(status !== undefined && !allowed.includes(status)) {
      return res.status(400).json({ message: 'Invalid status' });
    }

    const result = await db.query(
      `SELECT o.id, o.status, o.total, o.pickup_time, o.note, o.created_at,
              u.name AS student_name,
              (SELECT json_agg(
                        json_build_object(
                          'menu_item_id', oi.menu_item_id,
                          'name', mi.name,
                          'quantity', oi.quantity,
                          'unit_price', oi.unit_price
                        ) ORDER BY mi.name)
               FROM order_items oi
               JOIN menu_items mi ON mi.id = oi.menu_item_id
               WHERE oi.order_id = o.id) AS items
       FROM orders o
       JOIN users u ON u.id = o.student_id
       WHERE o.shop_id IN (SELECT id FROM shops WHERE owner_id = $1)
         AND ($2::text IS NULL OR o.status::text = $2)
       ORDER BY o.created_at DESC
       LIMIT 100`,
       [req.user.id, status]
    );

    res.json({ orders: result.rows });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});

router.patch('/:id/status', requireAuth, requireRole('shop_owner'), async (req, res) => {
  try{
    const {id} = req.params;
    const {status, pickup_time} = req.body;

    if(!UUID_RE.test(id)){
      return res.status(400).json({ message: 'Invalid order ID' });
    }

    if(status !== 'accepted' && status !== 'cancelled'){
      return res.status(400).json({ message: 'Invalid status' });
    }

    let pickupIso = null;
    if(status === 'accepted'){
      if (typeof pickup_time !== 'string' || Number.isNaN(Date.parse(pickup_time))) {
        return res.status(400).json({ message: 'Valid pickup_time (ISO 8601) is required to accept' });
      }
      
      const t = new Date(pickup_time).getTime();
      const now = Date.now();
      
      if (t < now + 5 * 60 * 1000) {
        return res.status(400).json({ message: 'pickup_time must be at least 5 minutes from now' });
      }
      
      if (t > now + 24 * 60 * 60 * 1000) {
        return res.status(400).json({ message: 'pickup_time must be within 24 hours' });
      }
      
      pickupIso = new Date(t).toISOString();
    }

    const result = await db.query(
      `UPDATE orders
       SET status = $1, pickup_time = $2
       WHERE id = $3
         AND status = 'pending'
         AND shop_id IN (SELECT id FROM shops WHERE owner_id = $4)
       RETURNING id, status, total, pickup_time, note, created_at`,
       [status, pickupIso, id, req.user.id]
    );

    if(result.rows.length === 0){
      return res.status(404).json({ message: 'Order not found or already processed' });
    }
    res.json({ order: result.rows[0] });
  } catch (err){
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});



module.exports = router;