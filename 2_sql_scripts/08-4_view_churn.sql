-- ============================================================================
-- View: Churn Risk Score
-- ============================================================================

CREATE VIEW [dw].[vw_Churn_Risk] AS
WITH order_gaps AS (
    -- Level 1: interval between consecutive purchases from customer
    SELECT
        fs.customer_key,
        cld.date_date AS order_date,
        fs.total_value,
        DATEDIFF(DAY,
            LAG(cld.date_date) OVER (PARTITION BY fs.customer_key ORDER BY cld.date_date),
            cld.date_date) AS days_since_prev_order
    FROM [dw].[Fact_Sales] fs
    JOIN [dw].[Dim_Calendar] cld ON fs.data_compra_key = cld.data_key
),
customer_metrics AS (
    -- Level 2: aggregate behavior metrics by customer
    SELECT
        customer_key,
        MAX(order_date)                                                        AS last_purchase,
        DATEDIFF(DAY, MAX(order_date), CAST(GETDATE() AS DATE))               AS days_since_purchase,
        COUNT(*)                                                               AS total_purchases,
        SUM(total_value)                                                       AS total_revenue,
        AVG(CAST(days_since_prev_order AS FLOAT))                             AS avg_cycle_days,
        STDEV(days_since_prev_order)                                          AS stdev_cycle_days
    FROM order_gaps
    GROUP BY customer_key
    HAVING COUNT(*) >= 3  -- customer must have a minimal of purchases for the query to work with
),
churn_scored AS (
    -- Level 3: calculates and classifies the risk score
    SELECT
        customer_key,
        last_purchase,
        days_since_purchase,
        total_purchases,
        total_revenue,
        ROUND(avg_cycle_days, 1) AS avg_cycle_days,
        ROUND(stdev_cycle_days, 1) AS cycle_variability,
        -- Razão entre silêncio atual e ciclo normal (>1 = fora do padrão)
        ROUND(days_since_purchase / NULLIF(avg_cycle_days, 0), 2) AS silence_ratio,
        -- Score 0-100: proporcional ao quanto o silêncio excede o ciclo médio
        LEAST(
            ROUND((days_since_purchase / NULLIF(avg_cycle_days, 0)) * 50, 0),
            100
        ) AS churn_risk_score,
        -- 4 categorias: separa "provável perda" de "em risco" e "perdido"
        CASE
            WHEN days_since_purchase > avg_cycle_days * 3 THEN 'Churned'
            WHEN days_since_purchase > avg_cycle_days * 2 THEN 'At Risk'
            WHEN days_since_purchase > avg_cycle_days     THEN 'Warning'
            ELSE                                               'Active'
        END AS churn_status
    FROM customer_metrics
)
SELECT
    cs.customer_key,
    dc.customer_id,
    cs.churn_status,
    cs.churn_risk_score,
    cs.last_purchase,
    cs.days_since_purchase,
    cs.avg_cycle_days,
    cs.cycle_variability,
    cs.silence_ratio,
    cs.total_purchases,
    cs.total_revenue
FROM churn_scored cs
JOIN [dw].[Dim_Clientes] dc ON cs.customer_key = dc.customer_key;
GO