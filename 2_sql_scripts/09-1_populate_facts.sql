WITH item_orders as (
    
    SELECT 
        soi.order_id,
        soi.order_item_id,
        dp.product_key,
        ds.seller_key,
        soi.price,
        soi.freight_value,
        (soi.price+soi.freight_value) as total_value,
        soi.shipping_limit_date
    FROM [staging].[stg_order_items] soi
    JOIN [dw].[Dim_Products] dp ON soi.product_id = dp.product_id
    JOIN [dw].[Dim_Sellers] ds ON soi.seller_id = ds.seller_id
),
aggregated_payments as (
    SELECT
        order_id,
        MAX(payment_installments) AS no_of_installments,
        SUM(payment_value) as payment_value
    FROM [staging].[stg_payments]
    GROUP BY [order_id]
),
calendar as (
    SELECT
        date_key,
        date_date
    FROM [dw].[Dim_Calendar]
),
orders AS(
    SELECT 
        io.order_id,
        dc.customer_key,
        io.product_key,
        io.seller_key,
        cld.date_key as purchase_date_key,
        cld2.date_key as delivery_date_key,
        io.price,
        io.freight_value,
        io.total_value,  
        ap.payment_value,
        ap.no_of_installments,
        io.shipping_limit_date,
        so.order_estimated_delivery_date,
        so.order_delivered_customer_date
    FROM [staging].[stg_orders] so
    LEFT JOIN item_orders io ON so.order_id = io.order_id
    LEFT JOIN [dw].[Dim_Customers] dc ON so.customer_id = dc.customer_id
    LEFT JOIN aggregated_payments ap ON so.order_id = ap.order_id
    LEFT JOIN calendar cld ON so.order_approved_at = cld.date_date
    LEFT JOIN calendar cld2 ON so.order_delivered_customer_date = cld.date_date 
)

SELECT * FROM orders;

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