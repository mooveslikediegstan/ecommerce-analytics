-- ============================================================================
-- 9. CRIAR PROCEDURE PARA CARGA DE DADOS
-- ============================================================================
 

CREATE PROCEDURE [dw].[sp_Load_Dimension_Clientes]
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
 
        -- CTE agrega os dados de pedidos por cliente antes do INSERT
        -- evitando duas subqueries correlacionadas no SELECT principal
        WITH pedidos_por_cliente AS (
            SELECT
                customer_id,
                MIN(CAST(order_purchase_timestamp AS DATE)) AS primeira_compra,
                COUNT(*)                                    AS total_compras
            FROM [staging].[stg_orders]
            GROUP BY customer_id
        ),
        clientes_novos AS (
            -- filtra apenas clientes que ainda não existem na dimensão
            SELECT
                sc.customer_id,
                sc.customer_unique_id,
                sc.customer_city,
                sc.customer_state,
                pc.primeira_compra,
                pc.total_compras
            FROM [staging].[stg_customers] sc
            INNER JOIN pedidos_por_cliente pc ON sc.customer_id = pc.customer_id
            LEFT JOIN  [dw].[Dim_Clientes] dc ON sc.customer_id = dc.cliente_id
            WHERE dc.cliente_id IS NULL  -- equivalente ao NOT EXISTS, mais legível
        )
        INSERT INTO [dw].[Dim_Clientes] (
            cliente_id,
            customer_unique_id,
            cidade,
            estado,
            data_primeira_compra,
            total_compras_historico
        )
        SELECT
            customer_id,
            customer_unique_id,
            customer_city,
            customer_state,
            primeira_compra,
            total_compras
        FROM clientes_novos;
 
        PRINT 'Dimensão Clientes carregada com sucesso!';
    END TRY
    BEGIN CATCH
        PRINT 'Erro na carga de Clientes: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO
 
 
CREATE PROCEDURE [dw].[sp_Load_Dimension_Produtos]
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
 
        -- CTE trata NULLs e filtra produtos já existentes
        WITH produtos_novos AS (
            SELECT
                sp.product_id,
                ISNULL(sp.product_category_name, 'Não Categorizados') AS categoria,
                sp.product_name_lenght,
                sp.product_description_lenght,
                sp.product_photos_qty,
                sp.product_weight_g,
                sp.product_length_cm,
                sp.product_height_cm,
                sp.product_width_cm
            FROM [staging].[stg_products] sp
            LEFT JOIN [dw].[Dim_Produtos] dp ON sp.product_id = dp.produto_id
            WHERE dp.produto_id IS NULL
        )
        INSERT INTO [dw].[Dim_Produtos] (
            produto_id,
            categoria_produto,
            nome_comprimento,
            descricao_comprimento,
            qtd_fotos,
            peso_g,
            comprimento_cm,
            altura_cm,
            largura_cm
        )
        SELECT
            product_id,
            categoria,
            product_name_lenght,
            product_description_lenght,
            product_photos_qty,
            product_weight_g,
            product_length_cm,
            product_height_cm,
            product_width_cm
        FROM produtos_novos;
 
        PRINT 'Dimensão Produtos carregada com sucesso!';
    END TRY
    BEGIN CATCH
        PRINT 'Erro na carga de Produtos: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO
 
 
CREATE PROCEDURE [dw].[sp_Load_Dimension_Sellers]
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
 
        -- CTE deduplica sellers do staging e filtra os já existentes
        WITH sellers_novos AS (
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
        FROM sellers_novos;
 
        PRINT 'Dimensão Sellers carregada com sucesso!';
    END TRY
    BEGIN CATCH
        PRINT 'Erro na carga de Sellers: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO