
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
            LEFT JOIN [staging].[stg_customers] sc ON so.customer_id = sc.customer_id
            LEFT JOIN [dw].[Dim_Customers] dc ON sc.customer_unique_id = dc.customer_unique_id
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

        PRINT 'Fact Sales loaded successfully!'+ CAST(@@ROWCOUNT AS VARCHAR);
    END TRY
    BEGIN CATCH
        PRINT 'Error loading Sales:' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO

CREATE PROCEDURE [dw].[sp_Load_Fact_Reviews]
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY

        WITH orders as (
            SELECT
                so.order_id,
                sc.customer_unique_id
            FROM [staging].[stg_orders] so
            LEFT JOIN [staging].[stg_customers] sc ON so.customer_id = sc.customer_id
        ),
        customers as (
            SELECT
                customer_key,
                customer_unique_id
            FROM [dw].[Dim_Customers]
        ),
        calendar as (
            SELECT
                date_key,
                date_date
            FROM [dw].[Dim_Calendar]
        ),
        reviews_to_fact as (
            SELECT
                sr.review_id,
                sr.order_id,
                c.customer_key,
                cld1.date_key as review_date_key,
                cld2.date_key as answer_date_key,
                sr.review_score,
                sr.review_comment_title,
                sr.review_comment_message,
                CASE 
                    WHEN review_answer_timestamp IS NULL THEN 0
                    ELSE 1
                END AS has_answer,
                CASE 
                    WHEN review_answer_timestamp IS NULL THEN 0
                    ELSE DATEDIFF(DAY,review_creation_date,review_answer_timestamp)
                END AS day_to_answer  
            FROM [staging].[stg_reviews] sr
            LEFT JOIN orders o ON sr.order_id = o.order_id
            LEFT JOIN customers c ON o.customer_unique_id = c.customer_unique_id
            LEFT JOIN calendar cld1 ON sr.review_creation_date = cld1.date_date
            LEFT JOIN calendar cld2 ON sr.review_answer_timestamp = cld2.date_date
        )
        INSERT INTO [dw].[Fact_Reviews] (
            review_id,
            order_id,
            customer_key,
            review_date_key,
            answer_date_key,
            review_score,
            review_comment_title,
            review_comment_message,
            has_answer,
            day_to_answer
        )
        SELECT
            review_id,
            order_id,
            customer_key,
            review_date_key,
            answer_date_key,
            review_score,
            review_comment_title,
            review_comment_message,
            has_answer,
            day_to_answer
        FROM reviews_to_fact;

        PRINT 'Fact Reviews loaded successfully! '+ CAST(@@ROWCOUNT AS VARCHAR);        
    END TRY
    BEGIN CATCH
        PRINT 'Error loading Reviews:' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO

CREATE PROCEDURE [dw].[sp_Load_Fact_Payments]
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY


        WITH sales_orders as (
            SELECT 
                so.order_id,
                sc.customer_unique_id,
                so.order_approved_at
            FROM [staging].[stg_orders] so
            LEFT JOIN [staging].[stg_customers] sc ON so.customer_id = sc.customer_id
        ),
        customers as (
            SELECT
                customer_key,
                customer_unique_id
            FROM [dw].[Dim_Customers]
        ),
        calendar as (
            SELECT
                date_key,
                date_date
            FROM [dw].[Dim_Calendar]
        ),
        order_payments as (
            SELECT 
                sp.order_id,
                c.customer_key,
                cld.date_key as purchase_date_key,
                dp.payment_key as payment_type_key,
                sp.payment_sequential,
                sp.payment_installments as no_of_installments,
                sp.payment_value
            FROM [staging].[stg_payments] sp
            LEFT JOIN sales_orders so ON sp.order_id = so.order_id
            LEFT JOIN customers c ON so.customer_unique_id = c.customer_unique_id
            LEFT JOIN calendar cld ON CAST(so.order_approved_at as DATE) = cld.date_date
            LEFT JOIN [dw].[Dim_Payment] dp ON sp.payment_type = dp.payment_type
        )
        INSERT INTO [dw].[Fact_Payments] (
            order_id,
            customer_key,
            purchase_date_key,
            payment_type_key,
            payment_sequential,
            no_of_installments,
            payment_value
        )
        SELECT
            order_id,
            customer_key,
            purchase_date_key,
            payment_type_key,
            payment_sequential,
            no_of_installments,
            payment_value
        FROM order_payments;

        PRINT 'Fact Payments loaded successfully! '+ CAST(@@ROWCOUNT AS VARCHAR);        
    END TRY
    BEGIN CATCH
        PRINT 'Error loading Payments:' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO