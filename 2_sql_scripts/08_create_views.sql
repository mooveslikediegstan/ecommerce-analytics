-- ============================================================================
-- 8. CRIAR VIEWS PARA ANÁLISES
-- ============================================================================
 
-- View: Resumo Mensal de Vendas
CREATE VIEW [dw].[vw_Vendas_Mensais] AS
SELECT 
    dd.ano,
    dd.mes,
    dd.nome_mes,
    COUNT(DISTINCT fv.order_id) as total_pedidos,
    COUNT(DISTINCT fv.cliente_key) as clientes_unicos,
    SUM(fv.valor_total) as receita_total,
    SUM(fv.quantidade) as itens_vendidos,
    ROUND(AVG(fv.valor_total), 2) as ticket_medio,
    ROUND(SUM(fv.valor_frete) / SUM(fv.valor_total) * 100, 2) as percentual_frete
FROM [dw].[Fact_Vendas] fv
JOIN [dw].[Dim_Data] dd ON fv.data_compra_key = dd.data_key
GROUP BY dd.ano, dd.mes, dd.nome_mes;
GO
 
-- View: Vendas por Categoria
CREATE VIEW [dw].[vw_Vendas_Por_Categoria] AS
SELECT 
    dp.categoria_produto,
    COUNT(DISTINCT fv.order_id) as total_pedidos,
    COUNT(DISTINCT fv.cliente_key) as clientes_unicos,
    SUM(fv.valor_total) as receita,
    ROUND(AVG(fv.valor_total), 2) as ticket_medio,
    ROUND(AVG(fv.dias_atraso), 2) as atraso_medio_dias
FROM [dw].[Fact_Vendas] fv
JOIN [dw].[Dim_Produtos] dp ON fv.produto_key = dp.produto_key
GROUP BY dp.categoria_produto;
GO
 
-- View: Performance de Sellers
CREATE VIEW [dw].[vw_Performance_Sellers] AS
SELECT 
    ds.seller_id,
    ds.seller_city,
    ds.seller_state,
    COUNT(DISTINCT fv.order_id) as total_vendas,
    SUM(fv.valor_total) as receita_total,
    ROUND(AVG(fv.valor_total), 2) as ticket_medio,
    ROUND(AVG(CAST(fr.nota_review AS FLOAT)), 2) as nota_media,
    COUNT(DISTINCT fr.review_id) as total_reviews,
    ROUND(AVG(fv.dias_para_entrega), 2) as dias_entrega_medio
FROM [dw].[Fact_Vendas] fv
JOIN [dw].[Dim_Sellers] ds ON fv.seller_key = ds.seller_key
LEFT JOIN [dw].[Fact_Reviews] fr ON fv.order_id = fr.order_id
GROUP BY ds.seller_id, ds.seller_city, ds.seller_state;
GO