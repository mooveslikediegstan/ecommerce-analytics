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
calendar as (
    SELECT
        date_key,
        date_date
    FROM [dw].[Dim_Calendar]
),
orders AS(
    SELECT
        so.order_id,
        dc.customer_key,
        io.product_key,
        io.seller_key,
        cld.date_key as purchase_date_key,
        cld2.date_key as delivery_date_key,
        ds.status_key,
        io.price,
        io.freight_value,
        io.total_value,
        CAST(io.shipping_limit_date as DATE) AS shipping_limit_date,
        CAST(so.order_estimated_delivery_date as DATE) AS order_estimated_delivery_date,
        CAST(so.order_delivered_customer_date as DATE) AS order_delivered_customer_date,
        CASE
            WHEN cld2.date_key IS NULL THEN NULL  -- pedido ainda não entregue
            ELSE DATEDIFF(DAY, cld.date_date, cld2.date_date)
        END AS days_to_deliver,
        CASE
            WHEN so.order_delivered_customer_date > io.shipping_limit_date THEN DATEDIFF(DAY,io.shipping_limit_date,so.order_delivered_customer_date)
            ELSE 0
        END AS delivery_delay
    FROM [staging].[stg_orders] so
    LEFT JOIN item_orders io ON so.order_id = io.order_id
    LEFT JOIN [dw].[Dim_Customers] dc ON so.customer_id = dc.customer_id
    LEFT JOIN aggregated_payments ap ON so.order_id = ap.order_id
    LEFT JOIN [dw].[Dim_Status] ds ON ds.status_name = so.order_status
    LEFT JOIN [dw].[Dim_Payment] dpay ON dpay.payment_type = ap.payment_type
    LEFT JOIN calendar cld ON CAST(so.order_approved_at AS DATE) = cld.date_date
    LEFT JOIN calendar cld2 ON CAST(so.order_delivered_customer_date AS DATE) = cld2.date_date 
)

SELECT TOP 100 * FROM orders;

-- Fact Sales (for reference)
-- CREATE TABLE [dw].[Fact_Sales] (
--     sales_key INT PRIMARY KEY IDENTITY(1,1),
--     order_id VARCHAR(50),
--     customer_key INT,
--     product_key INT,
--     seller_key INT,
--     purchase_date_key INT,
--     delivery_date_key INT,
--     status_key INT,
--     payment_key INT,
--     -- Metrics
--     quantity INT DEFAULT 1,
--     price DECIMAL(10,2),
--     freight_value DECIMAL(10,2),
--     total_value DECIMAL(10,2),
--     payment_value DECIMAL(10,2),
--     no_of_installments INT,
--     -- Dates
--     limit_delivery_date DATETIME2,
--     planned_delivery_date DATETIME2,
--     actual_delivery_date DATETIME2,
--     days_to_deliver INT,
--     delivery_delay INT,
--     -- Versioning
--     load_date DATETIME2 DEFAULT GETDATE(),
--     FOREIGN KEY (customer_key) REFERENCES [dw].[Dim_Customers](customer_key),
--     FOREIGN KEY (product_key) REFERENCES [dw].[Dim_Products](product_key),
--     FOREIGN KEY (seller_key) REFERENCES [dw].[Dim_Sellers](seller_key),
--     FOREIGN KEY (purchase_date_key) REFERENCES [dw].[Dim_Calendar](date_key),
--     FOREIGN KEY (delivery_date_key) REFERENCES [dw].[Dim_Calendar](date_key),
--     FOREIGN KEY (status_key) REFERENCES [dw].[Dim_Status](status_key),
--     FOREIGN KEY (payment_key) REFERENCES [dw].[Dim_Payment](payment_key)
-- );