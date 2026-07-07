-- ============================================================================
-- View: Sellers Performance
-- ============================================================================
 
CREATE VIEW [dw].[vw_Sellers_Performance] AS
SELECT 
    ds.seller_id,
    ds.seller_city,
    ds.seller_state,
    COUNT(DISTINCT fs.order_id) as sales_count,
    SUM(fs.total_value) as total_revenue,
    ROUND(AVG(fs.total_value), 2) as avg_ticket,
    ROUND(AVG(CAST(fr.nota_review AS FLOAT)), 2) as average_review_score,
    COUNT(DISTINCT fr.review_id) as review_count,
    ROUND(AVG(fs.days_to_deliver), 2) as average_days_to_deliver
FROM [dw].[Fact_Sales] fs
JOIN [dw].[Dim_Sellers] ds ON fs.seller_key = ds.seller_key
LEFT JOIN [dw].[Fact_Reviews] fr ON fs.order_id = fr.order_id
GROUP BY ds.seller_id, ds.seller_city, ds.seller_state;
GO