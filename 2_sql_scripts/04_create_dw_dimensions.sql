-- ============================================================================
-- 3. CREATE DIMENSION TABLES (Star Schema)
-- ============================================================================
 
USE Ecommerce_DW;
GO

-- Calendar
CREATE TABLE [dw].[Dim_Calendar] (
    date_key INT PRIMARY KEY,
    date_date DATE NOT NULL UNIQUE,
    date_year INT,
    date_month INT,
    month_name VARCHAR(20),
    day_of_month INT,
    date_weekday INT,
    date_weekday_name VARCHAR(20),
    date_quarter INT,
    date_yearweek INT,
    is_weekend BIT,
    is_holiday BIT DEFAULT 0
);
PRINT '''Dim_Calendar'' table created in ''dw'' schema.';

-- Customers
CREATE TABLE [dw].[Dim_Customers] (
    customer_key INT PRIMARY KEY IDENTITY(1,1),
    customer_id VARCHAR(50),
    customer_unique_id VARCHAR(50),
    city VARCHAR(100),
    city_state VARCHAR(2),
    first_purchase_date DATE,
    total_purchase_history INT,
    load_date DATETIME2 DEFAULT GETDATE(),
    is_active BIT DEFAULT 1
);
PRINT '''Dim_Customers'' table created in ''dw'' schema.';

-- Products
CREATE TABLE [dw].[Dim_Products] (
    product_key INT PRIMARY KEY IDENTITY(1,1),
    product_id VARCHAR(50),
    product_category VARCHAR(100),
    name_length INT,
    description_length INT,
    qtty_of_photos INT,
    weight_g FLOAT,
    length_cm FLOAT,
    height_cm FLOAT,
    width_cm FLOAT,
    volume_cm3 AS (CAST(length_cm * height_cm * width_cm AS FLOAT)),
    load_date DATETIME2 DEFAULT GETDATE()
);
PRINT '''Dim_Products'' table created in ''dw'' schema.';

-- Sellers
CREATE TABLE [dw].[Dim_Sellers] (
    seller_key INT PRIMARY KEY IDENTITY(1,1),
    seller_id VARCHAR(50),
    seller_city VARCHAR(100),
    seller_state VARCHAR(2),
    seller_region VARCHAR(50),
    load_date DATETIME2 DEFAULT GETDATE()
);
PRINT '''Dim_Sellers'' table created in ''dw'' schema.';
 
-- Order Status
CREATE TABLE [dw].[Dim_Status] (
    status_key INT PRIMARY KEY IDENTITY(1,1),
    status_name VARCHAR(20),
    status_description VARCHAR(100)
);
PRINT '''Dim_Status'' table created in ''dw'' schema.';

-- PaymentTypes
CREATE TABLE [dw].[Dim_Payment] (
    payment_key INT PRIMARY KEY IDENTITY(1,1),
    payment_type VARCHAR(20),
    payment_description VARCHAR(100)
);
PRINT '''Dim_Payment'' table created in ''dw'' schema.';
 
GO