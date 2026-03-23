-- eStore Database - Backup and Maintenance Scripts
-- Scripts for database backup, optimization, and maintenance

USE estore1;

-- 1. Database Backup Script (Export)
-- Run this command in MySQL client or command line:
-- mysqldump -u root -p estore1 > estore_backup_$(date +%Y%m%d_%H%M%S).sql

-- 2. Database Restore Script (Import)
-- Run this command in MySQL client or command line:
-- mysql -u root -p estore1 < estore_backup_filename.sql

-- 3. Database Optimization and Maintenance

-- Analyze tables for query optimization
ANALYZE TABLE users;
ANALYZE TABLE categories;
ANALYZE TABLE products;
ANALYZE TABLE productimages;
ANALYZE TABLE orders;
ANALYZE TABLE orderdetails;

-- Optimize tables to reclaim space and defragment
OPTIMIZE TABLE users;
OPTIMIZE TABLE categories;
OPTIMIZE TABLE products;
OPTIMIZE TABLE productimages;
OPTIMIZE TABLE orders;
OPTIMIZE TABLE orderdetails;

-- Check table status and health
SHOW TABLE STATUS FROM estore1;

-- 4. Performance Monitoring Queries

-- Check slow queries (requires slow query log to be enabled)
-- SHOW VARIABLES LIKE 'slow_query_log%';
-- SELECT * FROM mysql.slow_log ORDER BY start_time DESC LIMIT 10;

-- Check table sizes
SELECT 
    table_name,
    ROUND(((data_length + index_length) / 1024 / 1024), 2) AS 'Size (MB)',
    table_rows
FROM information_schema.tables 
WHERE table_schema = 'estore1'
ORDER BY (data_length + index_length) DESC;

-- Check index usage
SELECT 
    table_name,
    index_name,
    cardinality,
    sub_part,
    packed,
    nullable,
    index_type
FROM information_schema.statistics 
WHERE table_schema = 'estore1'
ORDER BY table_name, seq_in_index;

-- 5. Data Integrity Checks

-- Check for orphaned records
SELECT 'Orphaned product images (products deleted but images remain):' as check_type;
SELECT pi.* FROM productimages pi
LEFT JOIN products p ON pi.product_id = p.id
WHERE p.id IS NULL;

SELECT 'Orphaned order details (orders deleted but details remain):' as check_type;
SELECT od.* FROM orderdetails od
LEFT JOIN orders o ON od.orderId = o.orderId
WHERE o.orderId IS NULL;

-- Check for products without images
SELECT 'Products without images:' as check_type;
SELECT p.* FROM products p
LEFT JOIN productimages pi ON p.id = pi.product_id
WHERE pi.id IS NULL AND p.is_active = TRUE;

-- Check for products with zero stock
SELECT 'Products with zero stock:' as check_type;
SELECT * FROM products WHERE stock_quantity = 0 AND is_active = TRUE;

-- 6. Data Cleanup Scripts

-- Remove orphaned product images (backup first!)
-- DELETE pi FROM productimages pi
-- LEFT JOIN products p ON pi.product_id = p.id
-- WHERE p.id IS NULL;

-- Remove orphaned order details (backup first!)
-- DELETE od FROM orderdetails od
-- LEFT JOIN orders o ON od.orderId = o.orderId
-- WHERE o.orderId IS NULL;

-- Archive old orders (older than 1 year)
-- CREATE TABLE orders_archive LIKE orders;
-- INSERT INTO orders_archive 
-- SELECT * FROM orders 
-- WHERE orderDate < DATE_SUB(NOW(), INTERVAL 1 YEAR);
-- 
-- DELETE FROM orders 
-- WHERE orderDate < DATE_SUB(NOW(), INTERVAL 1 YEAR);

-- 7. User Management Scripts

-- Create a read-only user for reporting
-- CREATE USER 'estore_readonly'@'localhost' IDENTIFIED BY 'readonly_password';
-- GRANT SELECT ON estore1.* TO 'estore_readonly'@'localhost';

-- Create a user for application access
-- CREATE USER 'estore_app'@'localhost' IDENTIFIED BY 'app_password';
-- GRANT SELECT, INSERT, UPDATE, DELETE ON estore1.* TO 'estore_app'@'localhost';

-- 8. Statistics and Reports

-- Monthly sales report
SELECT 
    DATE_FORMAT(orderDate, '%Y-%m') as month,
    COUNT(*) as total_orders,
    SUM(total) as total_revenue,
    AVG(total) as avg_order_value
FROM orders 
WHERE orderStatus != 'cancelled'
GROUP BY DATE_FORMAT(orderDate, '%Y-%m')
ORDER BY month DESC;

-- Top selling products
SELECT 
    p.product_name,
    SUM(od.qty) as total_quantity_sold,
    SUM(od.amount) as total_revenue,
    COUNT(DISTINCT od.orderId) as number_of_orders
FROM orderdetails od
JOIN products p ON od.productId = p.id
JOIN orders o ON od.orderId = o.orderId
WHERE o.orderStatus != 'cancelled'
GROUP BY p.id, p.product_name
ORDER BY total_quantity_sold DESC
LIMIT 10;

-- Customer order statistics
SELECT 
    u.email,
    u.firstName,
    u.lastName,
    COUNT(o.orderId) as total_orders,
    SUM(o.total) as total_spent,
    AVG(o.total) as avg_order_value,
    MAX(o.orderDate) as last_order_date
FROM users u
LEFT JOIN orders o ON u.id = o.userId
GROUP BY u.id, u.email, u.firstName, u.lastName
ORDER BY total_spent DESC;

-- Category performance
SELECT 
    c.name as category_name,
    COUNT(DISTINCT p.id) as number_of_products,
    COUNT(DISTINCT od.orderId) as orders_with_category,
    SUM(od.qty) as total_quantity_sold,
    SUM(od.amount) as total_revenue
FROM categories c
LEFT JOIN products p ON c.id = p.category_id AND p.is_active = TRUE
LEFT JOIN orderdetails od ON p.id = od.productId
LEFT JOIN orders o ON od.orderId = o.orderId AND o.orderStatus != 'cancelled'
GROUP BY c.id, c.name
ORDER BY total_revenue DESC;

-- 9. Database Health Check
SELECT 'Database Health Check Summary:' as status;
SELECT 
    'Users' as table_name,
    COUNT(*) as record_count,
    MAX(updated_at) as last_update
FROM users
UNION ALL
SELECT 
    'Categories' as table_name,
    COUNT(*) as record_count,
    MAX(updated_at) as last_update
FROM categories
UNION ALL
SELECT 
    'Products' as table_name,
    COUNT(*) as record_count,
    MAX(updated_at) as last_update
FROM products
UNION ALL
SELECT 
    'Product Images' as table_name,
    COUNT(*) as record_count,
    MAX(created_at) as last_update
FROM productimages
UNION ALL
SELECT 
    'Orders' as table_name,
    COUNT(*) as record_count,
    MAX(updated_at) as last_update
FROM orders
UNION ALL
SELECT 
    'Order Details' as table_name,
    COUNT(*) as record_count,
    MAX(created_at) as last_update
FROM orderdetails;

-- 10. Security Audit

-- Check for users with weak passwords (example check)
SELECT 'Users with basic hashed passwords (consider additional security):' as security_note;
SELECT email, firstName, lastName, created_at 
FROM users 
WHERE password LIKE '$2a$10$%'
ORDER BY created_at DESC;

-- Check database permissions
SELECT 'Current database permissions:' as security_info;
SELECT * FROM information_schema.user_privileges 
WHERE grantee LIKE '%estore%';

-- Display completion message
SELECT 'Database maintenance and backup scripts completed!' as status;
