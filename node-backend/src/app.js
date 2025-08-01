const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const promClient = require('prom-client');
require('dotenv').config();

const { sequelize, setDbMetric } = require('./models');
const authRoutes = require('./routes/auth');
const productRoutes = require('./routes/products');
const inventoryRoutes = require('./routes/inventory');
const orderRoutes = require('./routes/orders');

const app = express();
const PORT = process.env.PORT || 8000;

// Prometheus metrics
const register = new promClient.Registry();
promClient.collectDefaultMetrics({ register });

// Custom metrics
const httpRequestDuration = new promClient.Histogram({
  name: 'node_app_request_latency_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'endpoint', 'status_code'],
  buckets: [0.005, 0.01, 0.025, 0.05, 0.075, 0.1, 0.25, 0.5, 0.75, 1.0, 2.5, 5.0, 7.5, 10.0]
});

const httpRequestCount = new promClient.Counter({
  name: 'node_app_request_count',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'endpoint', 'http_status']
});

const dbQueryDuration = new promClient.Histogram({
  name: 'node_app_db_query_duration_seconds',
  help: 'Duration of database queries in seconds',
  labelNames: ['operation'],
  buckets: [0.001, 0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5, 5.0]
});

register.registerMetric(httpRequestDuration);
register.registerMetric(httpRequestCount);
register.registerMetric(dbQueryDuration);

// Set the database metric for use in hooks
setDbMetric(dbQueryDuration);

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Custom Prometheus middleware
app.use((req, res, next) => {
  const start = Date.now();
  
  res.on('finish', () => {
    const duration = (Date.now() - start) / 1000;
    const endpoint = normalizeEndpoint(req.route?.path || req.path);
    
    httpRequestDuration
      .labels(req.method, endpoint, res.statusCode)
      .observe(duration);
    
    httpRequestCount
      .labels(req.method, endpoint, res.statusCode)
      .inc();
  });
  
  next();
});

// Normalize endpoints for metrics
function normalizeEndpoint(path) {
  return path
    .replace(/\/\d+/g, '/{id}')
    .replace(/\/[a-f0-9-]{36}/g, '/{uuid}');
}

// Routes
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/products', productRoutes);
app.use('/api/v1/inventory', inventoryRoutes);
app.use('/api/v1/orders', orderRoutes);

// Metrics endpoint
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});

// Health check
app.get('/', (req, res) => {
  res.json({ message: 'Backend Comparison - Node.js Version' });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Something went wrong!' });
});

// Initialize database and start server
async function startServer() {
  try {
    await sequelize.authenticate();
    console.log('Database connection established successfully.');
    
    // Don't sync in production, just authenticate
    // The tables already exist from Python backend
    console.log('Using existing database structure.');
    
    app.listen(PORT, () => {
      console.log(`Server running on port ${PORT}`);
    });
  } catch (error) {
    console.error('Unable to start server:', error);
    process.exit(1);
  }
}

startServer();

module.exports = app;
