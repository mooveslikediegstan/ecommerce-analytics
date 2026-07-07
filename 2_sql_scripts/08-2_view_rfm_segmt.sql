-- ============================================================================
-- View: RFM Segmentation
-- ============================================================================
CREATE VIEW [dw].[vw_RFM_Segmentation] AS
WITH base AS (
    -- Level 1: raw aggregation by customer
    SELECT
        dc.customer_key,
        dc.customer_id,
        DATEDIFF(DAY, MAX(fs.purchase_date_key), (SELECT MAX(date_key) FROM [dw].[Dim_Calendar])) AS recency_days,
        COUNT(DISTINCT fs.order_id) AS frequency,
        SUM(fs.total_value) AS money_value
    FROM [dw].[Dim_Customers] dc
    INNER JOIN [dw].[Fact_Sales] fs ON dc.customer_key = fs.customer_key
    GROUP BY dc.customer_key, dc.customer_id
),
rfm_scored AS (
    -- Level 2: apply NTILE over metrics above
    SELECT
        customer_key,
        customer_id,
        recency_days,
        frequency,
        monetary_value,
        -- Who bought more recently receives a greater score
        NTILE(5) OVER (ORDER BY recency_days DESC) AS recency_score,
        NTILE(5) OVER (ORDER BY frequency) AS frequency_score,
        NTILE(5) OVER (ORDER BY money_value) AS monetary_score
    FROM base
)

SELECT
    customer_key,
    customer_id,
    recency_days,
    frequency,
    monetary_value,
    recency_score,
    frequency_score,
    monetary_score,
    -- Score weighted: M=50%, R=30%, F=20%
    ROUND(
        (recency_score   * 0.30) +
        (frequency_score * 0.20) +
        (monetary_score  * 0.50),
        2
    ) AS weighted_rfm_score,
    -- Segmento baseado nos scores individuais
    CASE
        WHEN recency_score >= 4 AND frequency_score >= 4 AND monetary_score >= 4 THEN 'Campeão'
        WHEN recency_score <= 2 AND frequency_score >= 4 AND monetary_score >= 4 THEN 'Em Risco'
        WHEN recency_score >= 4 AND frequency_score <= 2 THEN 'Promissor'
        WHEN recency_score >= 3 AND frequency_score >= 3 AND monetary_score >= 3 THEN 'Leal'
        WHEN recency_score <= 1 AND frequency_score <= 1 AND monetary_score <= 1 THEN 'Perdido'
        ELSE 'Potencial'
    END AS segment
FROM rfm_scored;
GO