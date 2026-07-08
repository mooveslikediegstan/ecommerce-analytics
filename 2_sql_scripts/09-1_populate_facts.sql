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