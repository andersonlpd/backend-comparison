const express = require('express');
const { Order, OrderItem, Product, InventoryItem } = require('../models');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

// Get orders
router.get('/', authenticateToken, async (req, res) => {
  try {
    const { skip = 0, limit = 100 } = req.query;
    const orders = await Order.findAll({
      where: { customer_id: req.user.id },
      offset: parseInt(skip),
      limit: parseInt(limit),
      include: [{
        model: OrderItem,
        as: 'items',
        include: [{
          model: Product,
          as: 'product'
        }]
      }]
    });
    res.json(orders);
  } catch (error) {
    console.error('Get orders error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Create order
router.post('/', authenticateToken, async (req, res) => {
  try {
    const { status = 'pending', items } = req.body;

    // Create order
    const order = await Order.create({
      customer_id: req.user.id,
      status,
      total_amount: 0
    });

    let totalAmount = 0;

    // Create order items and update inventory
    for (const itemData of items) {
      const { product_id, quantity, unit_price } = itemData;

      // Check product exists
      const product = await Product.findByPk(product_id);
      if (!product) {
        await order.destroy();
        return res.status(404).json({ error: `Product ${product_id} not found` });
      }

      // Check inventory
      const inventory = await InventoryItem.findOne({ where: { product_id } });
      if (!inventory || inventory.quantity < quantity) {
        await order.destroy();
        return res.status(400).json({ 
          error: `Not enough items in inventory for product ${product_id}` 
        });
      }

      // Create order item
      await OrderItem.create({
        order_id: order.id,
        product_id,
        quantity,
        unit_price
      });

      // Update inventory
      inventory.quantity -= quantity;
      inventory.last_updated = new Date();
      await inventory.save();

      totalAmount += quantity * unit_price;
    }

    // Update order total
    order.total_amount = totalAmount;
    await order.save();

    // Fetch complete order with items
    const completeOrder = await Order.findByPk(order.id, {
      include: [{
        model: OrderItem,
        as: 'items',
        include: [{
          model: Product,
          as: 'product'
        }]
      }]
    });

    res.status(201).json(completeOrder);
  } catch (error) {
    console.error('Create order error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get order by ID
router.get('/:id', authenticateToken, async (req, res) => {
  try {
    const order = await Order.findByPk(req.params.id, {
      include: [{
        model: OrderItem,
        as: 'items',
        include: [{
          model: Product,
          as: 'product'
        }]
      }]
    });

    if (!order) {
      return res.status(404).json({ error: 'Order not found' });
    }

    if (order.customer_id !== req.user.id) {
      return res.status(403).json({ error: 'Not enough permissions' });
    }

    res.json(order);
  } catch (error) {
    console.error('Get order error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;
