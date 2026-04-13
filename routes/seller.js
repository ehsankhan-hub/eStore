const express = require("express");
const router = express.Router();
const multer = require("multer");
const path = require("path");
const mysql = require("mysql2");

// Database connection (using environment variables)
const pool = mysql.createPool({
  host: process.env.DB_HOST || "localhost",
  user: process.env.DB_USER || "root",
  password: process.env.DB_PASSWORD || "password",
  database: process.env.DB_NAME || "estore1",
  port: process.env.DB_PORT || 3306,
}).promise();

// Multer Storage Configuration
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, path.join(__dirname, "../uploads"));
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + "-" + Math.round(Math.random() * 1e9);
    cb(null, uniqueSuffix + path.extname(file.originalname));
  },
});

const upload = multer({ 
    storage: storage,
    limits: { fileSize: 10 * 1024 * 1024 } // 10MB limit
});

// @route   POST /api/seller/product
// @desc    Add a new product with images
router.post("/product", upload.array("images", 10), async (req, res) => {
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();

    const { product_name, category_id, description, price, seller_id } = req.body;
    const stock_quantity = req.body.stock_quantity || 10;
    const sku = "SKU-" + Date.now();

    // 1. Insert into products table
    const [productResult] = await connection.query(
      `INSERT INTO products (product_name, category_id, description, price, seller_id, stock_quantity, sku) 
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [product_name, category_id, description, price, seller_id || 1, stock_quantity, sku]
    );

    const productId = productResult.insertId;

    // 2. Insert into productimages table
    if (req.files && req.files.length > 0) {
      for (let i = 0; i < req.files.length; i++) {
        const file = req.files[i];
        const isPrimary = i === 0 ? 1 : 0;
        await connection.query(
          `INSERT INTO productimages (product_id, imageFiles, display_order, is_primary) 
           VALUES (?, ?, ?, ?)`,
          [productId, file.filename, i, isPrimary]
        );
      }
    }

    await connection.commit();
    res.status(201).json({ 
        message: "Product created successfully", 
        productId: productId,
        files: req.files ? req.files.map(f => f.filename) : []
    });
  } catch (error) {
    await connection.rollback();
    console.error("Error creating product:", error);
    res.status(500).json({ error: "Failed to create product", details: error.message });
  } finally {
    connection.release();
  }
});

// @route   GET /api/seller/products/:sellerId
// @desc    Get products for a specific seller
router.get("/products/:sellerId", async (req, res) => {
  try {
    const sellerId = req.params.sellerId;
    
    // We use the view products_with_images if it exists, or a raw query
    const [rows] = await pool.query(
      `SELECT p.*, 
        JSON_ARRAYAGG(pi.imageFiles) as galleryImages
       FROM products p
       LEFT JOIN productimages pi ON p.id = pi.product_id
       WHERE p.seller_id = ?
       GROUP BY p.id`,
      [sellerId]
    );

    // Parse galleryImages if it comes as a string (depends on MySQL version/driver)
    const processedRows = rows.map(row => {
        if (typeof row.galleryImages === 'string') {
            try {
                row.galleryImages = JSON.parse(row.galleryImages);
            } catch (e) {
                row.galleryImages = [];
            }
        }
        return row;
    });

    res.json(processedRows);
  } catch (error) {
    console.error("Error fetching seller products:", error);
    res.status(500).json({ error: "Failed to fetch products", details: error.message });
  }
});

module.exports = router;
