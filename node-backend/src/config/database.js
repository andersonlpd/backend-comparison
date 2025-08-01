const { Sequelize } = require('sequelize');

let dbQueryDuration;

const sequelize = new Sequelize(
  process.env.DATABASE_URL || 'postgresql://postgres:postgres@localhost:5432/inventory',
  {
    dialect: 'postgres',
    logging: process.env.NODE_ENV === 'development' ? console.log : false,
    pool: {
      max: 10,
      min: 0,
      acquire: 30000,
      idle: 10000
    },
    hooks: {
      beforeQuery: (options) => {
        options.startTime = Date.now();
      },
      afterQuery: (options, query) => {
        if (dbQueryDuration) {
          const duration = (Date.now() - options.startTime) / 1000;
          const operation = getOperationType(query.sql);
          dbQueryDuration.labels(operation).observe(duration);
        }
      }
    }
  }
);

function getOperationType(sql) {
  const upperSql = sql.trim().toUpperCase();
  if (upperSql.startsWith('SELECT')) return 'SELECT';
  if (upperSql.startsWith('INSERT')) return 'INSERT';
  if (upperSql.startsWith('UPDATE')) return 'UPDATE';
  if (upperSql.startsWith('DELETE')) return 'DELETE';
  return 'OTHER';
}

// Function to set the metric instance from app.js
function setDbMetric(metric) {
  dbQueryDuration = metric;
}

module.exports = { sequelize, setDbMetric };
