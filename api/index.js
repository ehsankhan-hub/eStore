const express = require("express");
require('dotenv').config({ path: '../.env' });
const cors = require("cors");
const mysql = require("mysql2");

const app = express();
const PORT = process.env.PORT || 5004;

// Middleware
app.use(cors());
app.use(express.json());

// Database connection
const pool = mysql.createPool({
  host: process.env.DB_HOST || "localhost",
  user: process.env.DB_USER || "root",
  password: process.env.DB_PASSWORD || "password",
  database: process.env.DB_NAME || "estore1",
  port: process.env.DB_PORT || 3306,
  multipleStatements: true,
});

// Health check
app.get("/", (req, res) => {
  res.json({
    message: "eStore API is running on Railway!",
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || "development"
  });
});

// Test database connection
app.get("/test-db", (req, res) => {
  pool.query("SELECT 1 as test", (err, results) => {
    if (err) {
      res.status(500).json({ error: "Database connection failed", details: err.message });
    } else {
      res.json({ message: "Database connected successfully!", result: results[0] });
    }
  });
});

// Import your routes (we'll create simple versions)
const productCategories = require("../routes/productCategories");
const products = require("../routes/products");
const users = require("../routes/users");
const orders = require("../routes/orders");

// Use routes
app.use("/api/productCategories", productCategories);
app.use("/api/products", products);
app.use("/api/users", users);
app.use("/api/orders", orders);

// Start server
app.listen(PORT, () => {
  console.log(`🚀 eStore API running on port ${PORT}`);
  console.log(`🌐 Environment: ${process.env.NODE_ENV || "development"}`);
});

module.exports = app;
