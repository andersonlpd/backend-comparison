const express = require('express');
const { InventoryItem, Product } = require('../models');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

// Get inventory
router.get('/', authenticateToken, async (req, res) => {
  try {
    const { skip = 0, limit = 100 } = req.query;
    const inventory = await InventoryItem.findAll({
      offset: parseInt(skip),
      limit: parseInt(limit),
      include: [{
        model: Product,
        as: 'product'
      }]
    });
    res.json(inventory);
  } catch (error) {
    console.error('Get inventory error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Add to inventory
router.post('/add', authenticateToken, async (req, res) => {
  try {
    const { product_id, quantity } = req.body;

    const product = await Product.findByPk(product_id);
    if (!product) {
      return res.status(404).json({ error: 'Product not found' });
    }

    let inventoryItem = await InventoryItem.findOne({ where: { product_id } });
    
    if (inventoryItem) {
      inventoryItem.quantity += quantity;
      inventoryItem.last_updated = new Date();
      await inventoryItem.save();
    } else {
      inventoryItem = await InventoryItem.create({
        product_id,
        quantity,
        last_updated: new Date()
      });
    }

    res.json(inventoryItem);
  } catch (error) {
    console.error('Add inventory error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Remove from inventory
router.post('/remove', authenticateToken, async (req, res) => {
  try {
    const { product_id, quantity } = req.body;

    const inventoryItem = await InventoryItem.findOne({ where: { product_id } });
    if (!inventoryItem) {
      return res.status(404).json({ error: 'Inventory item not found' });
    }

    if (inventoryItem.quantity < quantity) {
      return res.status(400).json({ error: 'Insufficient inventory' });
    }

    inventoryItem.quantity -= quantity;
    inventoryItem.last_updated = new Date();
    await inventoryItem.save();

    res.json(inventoryItem);
  } catch (error) {
    console.error('Remove inventory error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;
