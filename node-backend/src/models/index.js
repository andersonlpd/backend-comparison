const { Sequelize, DataTypes } = require('sequelize');
const { sequelize, setDbMetric } = require('../config/database');

// Import models
const User = require('./User')(sequelize, DataTypes);
const Product = require('./Product')(sequelize, DataTypes);
const InventoryItem = require('./InventoryItem')(sequelize, DataTypes);
const Order = require('./Order')(sequelize, DataTypes);
const OrderItem = require('./OrderItem')(sequelize, DataTypes);

// Define associations
User.hasMany(Product, { foreignKey: 'owner_id', as: 'products' });
Product.belongsTo(User, { foreignKey: 'owner_id', as: 'owner' });

Product.hasOne(InventoryItem, { foreignKey: 'product_id', as: 'inventory' });
InventoryItem.belongsTo(Product, { foreignKey: 'product_id', as: 'product' });

User.hasMany(Order, { foreignKey: 'customer_id', as: 'orders' });
Order.belongsTo(User, { foreignKey: 'customer_id', as: 'customer' });

Order.hasMany(OrderItem, { foreignKey: 'order_id', as: 'items' });
OrderItem.belongsTo(Order, { foreignKey: 'order_id', as: 'order' });

Product.hasMany(OrderItem, { foreignKey: 'product_id', as: 'orderItems' });
OrderItem.belongsTo(Product, { foreignKey: 'product_id', as: 'product' });

module.exports = {
  sequelize,
  setDbMetric,
  User,
  Product,
  InventoryItem,
  Order,
  OrderItem
};
