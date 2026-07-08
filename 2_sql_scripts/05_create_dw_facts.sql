-- ============================================================================
-- 4. CREATE SALES AND REVIEW FACT TABLES
-- ============================================================================

USE Ecommerce_DW;
GO 

-- Fact Vendas
CREATE TABLE [dw].[Fact_Sales] (
    sales_key INT PRIMARY KEY IDENTITY(1,1),
    order_id VARCHAR(50),
    customer_key INT,
    product_key INT,
    seller_key INT,
    purchase_date_key INT,
    delivery_date_key INT,
    status_key INT,
    payment_key INT,
    -- Metrics
    quantity INT DEFAULT 1,
    price DECIMAL(10,2),
    freight_value DECIMAL(10,2),
    total_value DECIMAL(10,2),
    payment_value DECIMAL(10,2),
    no_of_installments INT,
    -- Dates
    limit_delivery_date DATETIME2,
    planned_delivery_date DATETIME2,
    actual_delivery_date DATETIME2,
    days_to_deliver INT,
    delivery_delay INT,
    -- Versioning
    load_date DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (customer_key) REFERENCES [dw].[Dim_Customers](customer_key),
    FOREIGN KEY (product_key) REFERENCES [dw].[Dim_Products](product_key),
    FOREIGN KEY (seller_key) REFERENCES [dw].[Dim_Sellers](seller_key),
    FOREIGN KEY (purchase_date_key) REFERENCES [dw].[Dim_Calendar](date_key),
    FOREIGN KEY (delivery_date_key) REFERENCES [dw].[Dim_Calendar](date_key),
    FOREIGN KEY (status_key) REFERENCES [dw].[Dim_Status](status_key),
    FOREIGN KEY (payment_key) REFERENCES [dw].[Dim_Payment](payment_key)
);
PRINT '''Fact_Sales'' table created in ''dw'' schema.';

 
-- Fact Reviews
CREATE TABLE [dw].[Fact_Reviews] (
    review_key INT PRIMARY KEY IDENTITY(1,1),
    review_id VARCHAR(50),
    order_id VARCHAR(50),
    customer_key INT,
    product_key INT,
    review_date_key INT,
    answer_date_key INT,
    -- Metrics
    review_score INT,
    review_comment_title VARCHAR(100),
    review_comment_message VARCHAR(MAX),
    has_answer BIT,
    day_to_answer INT,
    -- Versioning
    load_date DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (customer_key) REFERENCES [dw].[Dim_Customers](customer_key),
    FOREIGN KEY (product_key) REFERENCES [dw].[Dim_Products](product_key),
    FOREIGN KEY (review_date_key) REFERENCES [dw].[Dim_Calendar](date_key),
    FOREIGN KEY (answer_date_key) REFERENCES [dw].[Dim_Calendar](date_key)
);
PRINT '''Fact_Reviews'' table created in ''dw'' schema.';

CREATE TABLE [dw].[Fact_Payments] (
    payment_key        INT PRIMARY KEY IDENTITY(1,1),
    order_id           VARCHAR(50),
    customer_key       INT,
    purchase_date_key  INT,
    payment_type_key   INT,
    payment_sequential INT,
    no_of_installments INT,
    payment_value      DECIMAL(10,2),
    load_date          DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (customer_key)     REFERENCES [dw].[Dim_Customers](customer_key),
    FOREIGN KEY (purchase_date_key) REFERENCES [dw].[Dim_Calendar](date_key),
    FOREIGN KEY (payment_type_key) REFERENCES [dw].[Dim_Payment](payment_key)
);
PRINT '''Fact_Payments'' table created in ''dw'' schema.';
GO