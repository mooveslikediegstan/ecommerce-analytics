-- ============================================================================
-- 9. CREATE PROCEDURES TO LOAD DW DIMENSIONS
-- ============================================================================
 

CREATE PROCEDURE [dw].[sp_Load_Dimension_Customers]
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
 
        -- CTE aggregates order data by customer before INSERT command

        WITH orders_by_customer AS (
            SELECT
                customer_id,
                MIN(CAST(order_purchase_timestamp AS DATE)) AS first_purchase,
                COUNT(*) AS total_purchases
            FROM [staging].[stg_orders]
            GROUP BY customer_id
        ),
        new_customers AS (
            -- filter only the customers which do not exist in the dimension
            SELECT
                sc.customer_id,
                sc.customer_unique_id,
                sc.customer_city,
                sc.customer_state,
                oc.first_purchase,
                oc.total_sales
            FROM [staging].[stg_customers] sc
            INNER JOIN orders_by_customer oc ON sc.customer_id = pc.customer_id
            LEFT JOIN  [dw].[Dim_Customers] dc ON sc.customer_id = dc.customer_id
            WHERE dc.customer_id IS NULL  -- equivalent to NOT EXISTS, much cleaner
        )
        INSERT INTO [dw].[Dim_Customers] (
            customer_id,
            customer_unique_id,
            city,
            city_state,
            first_purchase_date,
            total_purchase_history
        )
        SELECT
            customer_id,
            customer_unique_id,
            customer_city,
            customer_state,
            first_purchase,
            total_sales
        FROM new_customers;
 
        PRINT 'Customer Dim loaded successfully!';
    END TRY
    BEGIN CATCH
        PRINT 'Error on loading Customers: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO
 
 
CREATE PROCEDURE [dw].[sp_Load_Dimension_Products]
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
 
        -- CTE treats NULLs and filters existing products
        WITH new_products AS (
            SELECT
                sp.product_id,
                ISNULL(sp.product_category_name, 'Not categorized') AS category,
                sp.product_name_lenght,
                sp.product_description_lenght,
                sp.product_photos_qty,
                sp.product_weight_g,
                sp.product_length_cm,
                sp.product_height_cm,
                sp.product_width_cm
            FROM [staging].[stg_products] sp
            LEFT JOIN [dw].[Dim_Products] dp ON sp.product_id = dp.product_id
            WHERE dp.product_id IS NULL
        )
        INSERT INTO [dw].[Dim_Products] (
            product_id,
            product_category,
            name_length,
            description_length,
            qtty_of_photos,
            weight_g,
            length_cm,
            height_cm,
            width_cm
        )
        SELECT
            product_id,
            category,
            product_name_lenght,
            product_description_lenght,
            product_photos_qty,
            product_weight_g,
            product_length_cm,
            product_height_cm,
            product_width_cm
        FROM new_products;
 
        PRINT 'Products loaded successfully!';
    END TRY
    BEGIN CATCH
        PRINT 'Error loading Products:' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO
 
 
CREATE PROCEDURE [dw].[sp_Load_Dimension_Sellers]
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
 
        -- CTE filters existing Sellers
        WITH new_sellers AS (
            SELECT DISTINCT
                ss.seller_id,
                ss.seller_city,
                ss.seller_state
            FROM [staging].[stg_sellers] ss
            LEFT JOIN [dw].[Dim_Sellers] ds ON ss.seller_id = ds.seller_id
            WHERE ds.seller_id IS NULL
        )
        INSERT INTO [dw].[Dim_Sellers] (
            seller_id,
            seller_city,
            seller_state
        )
        SELECT
            seller_id,
            seller_city,
            seller_state
        FROM new_sellers;
 
        PRINT 'Sellers loaded successfully!';
    END TRY
    BEGIN CATCH
        PRINT 'Error loading Sellers: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO