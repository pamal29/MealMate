const express = require('express');
const db = require('../../config/db');
const { requireAuth, requireRole } = require('../../middleware/auth');

const router = express.Router();

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

router.post('/', requireAuth, requireRole('student'), async (req, res) => {
  try{
    const {shop_id, items, pickup_time, note} = req.body;

    if(typeof shop_id !== 'string' || !UUID_RE.test(shop_id)) {
      return res.status(400).json({ message: 'Invalid shop ID' });
    }

    if(!Array.isArray(items) || items.length === 0) {
      return res.status(400).json({ message: 'Items are required' });
    } 

    const seen = new Set();
    for (const it in items){
      if(
        !it ||
        typeof it.menu_item_id !== 'string' ||
        !UUID_RE.test(it.menu_item_id) 
      ) {
        return res.status(400).json({ message: 'Invalid menu item ID' });
      }

      if(!Number.isInteger(it.quantity) || it.quantity <= 0 || it.quantity >20) {
        return res.status(400).json({ message: 'quantity must be between 1 to 20' });
      }

      if (seen.has(it.menu_item_id)) {
        return res.status(400).json({ message: 'Duplicate menu item found' });
      }
      seen.add(it.menu_item_id);
    }

    if(note !== undefined && typeof note !== 'string' || note.length > 200) {
      return res.status(400).json({ message: 'note must be a string up to 200 characters' });
    }

    // TODO next step: pickup_time check, then DB logic in a transaction
    res.status(501).json({ message: 'Not implemented yet' });

  }catch(err){
    console.error(err);
    res.status(500).json({ message: 'Internal server error' });
  }
});

module.exports = router;