-- ============================================================================
-- 2. CREATE STAGING TABLES
-- ============================================================================

USE Ecommerce_DW;
GO
-- Orders
CREATE TABLE [staging].[stg_orders] (
    order_id VARCHAR(50) NOT NULL PRIMARY KEY,
    customer_id VARCHAR(50),
    order_status VARCHAR(20),
    order_purchase_timestamp DATETIME2,
    order_approved_at DATETIME2,
    order_delivered_carrier_date DATETIME2,
    order_delivered_customer_date DATETIME2,
    order_estimated_delivery_date DATETIME2
);
PRINT 'Created Orders table.';
 
-- Customers
CREATE TABLE [staging].[stg_customers] (
    customer_id VARCHAR(50) NOT NULL PRIMARY KEY,
    customer_unique_id VARCHAR(50),
    customer_zip_code_prefix VARCHAR(10),
    customer_city VARCHAR(100),
    customer_state VARCHAR(2)
);
PRINT 'Created Customers table.';
 
-- Products
CREATE TABLE [staging].[stg_products] (
    product_id VARCHAR(50) NOT NULL PRIMARY KEY,
    product_category_name VARCHAR(100),
    product_name_lenght INT,
    product_description_lenght INT,
    product_photos_qty INT,
    product_weight_g FLOAT,
    product_length_cm FLOAT,
    product_height_cm FLOAT,
    product_width_cm FLOAT
);
PRINT 'Created Products table.';
 
-- Order Items
CREATE TABLE [staging].[stg_order_items] (
    order_id VARCHAR(50),
    order_item_id INT,
    product_id VARCHAR(50),
    seller_id VARCHAR(50),
    shipping_limit_date DATETIME2,
    price DECIMAL(10,2),
    freight_value DECIMAL(10,2)
);
PRINT 'Created Order Items table.';
 
-- Order Payments
CREATE TABLE [staging].[stg_payments] (
    order_id VARCHAR(50),
    payment_sequential INT,
    payment_type VARCHAR(20),
    payment_installments INT,
    payment_value DECIMAL(10,2)
);
PRINT 'Created Payments table.';
 
-- Order Reviews
CREATE TABLE [staging].[stg_reviews] (
    review_id               VARCHAR(50),
    order_id                VARCHAR(50),
    review_score            INT,
    review_comment_title    VARCHAR(100),
    review_comment_message  VARCHAR(MAX),
    review_creation_date    VARCHAR(50),
    review_answer_timestamp VARCHAR(50)    
);
PRINT 'Created Reviews table.';
 
-- Sellers (Retailers)
CREATE TABLE [staging].[stg_sellers] (
    seller_id VARCHAR(50) NOT NULL PRIMARY KEY,
    seller_zip_code_prefix VARCHAR(10),
    seller_city VARCHAR(100),
    seller_state VARCHAR(2)
);
PRINT 'Created Sellers table.';

CREATE TABLE [staging].[geolocation] (
    geolocation_zip_code_prefix VARCHAR(10),
    geolocation_lat             DECIMAL(9,6),
    geolocation_lng             DECIMAL(9,6),
    geolocation_city            VARCHAR(100),
    geolocation_state           VARCHAR(2)
);
PRINT 'Created Geolocation table.';
PRINT 'Done';
GO
 
 