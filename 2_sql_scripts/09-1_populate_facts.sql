
CREATE PROCEDURE [dw].[sp_Load_Fact_Sales]
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY

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
        sales_orders AS(
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
                CAST(io.shipping_limit_date as DATE) AS limit_delivery_date,
                CAST(so.order_estimated_delivery_date as DATE) AS planned_delivery_date,
                CAST(so.order_delivered_customer_date as DATE) AS actual_delivery_date,
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
            LEFT JOIN [dw].[Dim_Status] ds ON ds.status_name = so.order_status
            LEFT JOIN calendar cld ON CAST(so.order_approved_at AS DATE) = cld.date_date
            LEFT JOIN calendar cld2 ON CAST(so.order_delivered_customer_date AS DATE) = cld2.date_date 
        )
        INSERT INTO [dw].[Fact_Sales] (
            order_id,
            customer_key,
            product_key,
            seller_key,
            purchase_date_key,
            delivery_date_key,
            status_key,
            price,
            freight_value,
            total_value,
            limit_delivery_date,
            planned_delivery_date,
            actual_delivery_date,
            days_to_deliver,
            delivery_delay
        )
        SELECT
            order_id,
            customer_key,
            product_key,
            seller_key,
            purchase_date_key,
            delivery_date_key,
            status_key,
            price,
            freight_value,
            total_value,
            limit_delivery_date,
            planned_delivery_date,
            actual_delivery_date,
            days_to_deliver,
            delivery_delay
        FROM sales_orders;

        PRINT 'Fact Sales loaded successfully!'+ CAST(@@ROWCOUNT AS VARCHAR);;
    END TRY
    BEGIN CATCH
        PRINT 'Error loading Sales:' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO