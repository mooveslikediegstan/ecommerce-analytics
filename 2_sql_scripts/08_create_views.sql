-- ============================================================================
-- 8. CREATE VIEWS FOR ANALYSIS
-- ============================================================================

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
    ROUND(AVG(CAST(fr.review_score AS FLOAT)), 2) as average_review_score,
    COUNT(DISTINCT fr.review_id) as review_count,
    ROUND(AVG(fs.days_to_deliver), 2) as average_days_to_deliver
FROM [dw].[Fact_Sales] fs
JOIN [dw].[Dim_Sellers] ds ON fs.seller_key = ds.seller_key
LEFT JOIN [dw].[Fact_Reviews] fr ON fs.order_id = fr.order_id
GROUP BY ds.seller_id, ds.seller_city, ds.seller_state;
GO

-- ============================================================================
-- View: RFM Segmentation
-- ============================================================================
CREATE VIEW [dw].[vw_RFM_Segmentation] AS
WITH base AS (
    -- Level 1: raw aggregation by customer
    SELECT
        dc.customer_key,
        dc.customer_unique_id,
        DATEDIFF(DAY, MAX(fs.purchase_date_key), (SELECT MAX(date_key) FROM [dw].[Dim_Calendar])) AS recency_days,
        COUNT(DISTINCT fs.order_id) AS frequency,
        SUM(fs.total_value) AS monetary_value
    FROM [dw].[Dim_Customers] dc
    INNER JOIN [dw].[Fact_Sales] fs ON dc.customer_key = fs.customer_key
    GROUP BY dc.customer_key, dc.customer_unique_id
),
rfm_scored AS (
    -- Level 2: apply NTILE over metrics above
    SELECT
        customer_key,
        customer_unique_id,
        recency_days,
        frequency,
        monetary_value,
        -- Who bought more recently receives a greater score
        NTILE(5) OVER (ORDER BY recency_days DESC) AS recency_score,
        NTILE(5) OVER (ORDER BY frequency) AS frequency_score,
        NTILE(5) OVER (ORDER BY monetary_value) AS monetary_score
    FROM base
)

SELECT
    customer_key,
    customer_unique_id,
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
        WHEN recency_score >= 4 AND frequency_score >= 4 AND monetary_score >= 4 THEN 'Champion'
        WHEN recency_score <= 2 AND frequency_score >= 4 AND monetary_score >= 4 THEN 'At Risk'
        WHEN recency_score >= 4 AND frequency_score <= 2 THEN 'Promissor'
        WHEN recency_score >= 3 AND frequency_score >= 3 AND monetary_score >= 3 THEN 'Loyal'
        WHEN recency_score <= 1 AND frequency_score <= 1 AND monetary_score <= 1 THEN 'Lost'
        ELSE 'Potential'
    END AS segment
FROM rfm_scored;
GO




-- ============================================================================
-- View: Cohort Analysis (Monthly Retention)
-- ============================================================================
CREATE VIEW [dw].[vw_Cohort_Retention] AS
WITH first_purchase AS (
    -- Level 1: 1st purchase of each customer
    SELECT
        dc.customer_key,
        DATEFROMPARTS(YEAR(cld.date_date), MONTH(cld.date_date), 1) AS cohort_month
    FROM [dw].[Fact_Sales] fs
    JOIN [dw].[Dim_Customers] dc ON fs.customer_key = dc.customer_key
    JOIN [dw].[Dim_Calendar] cld ON fs.purchase_date_key = cld.date_key
    GROUP BY dc.customer_key, YEAR(cld.date_date), MONTH(cld.date_date)
    HAVING DATEFROMPARTS(YEAR(cld.date_date), MONTH(cld.date_date), 1) =
           MIN(DATEFROMPARTS(YEAR(cld.date_date), MONTH(cld.date_date), 1))
),
monthly_activity AS (
    -- Level 2: one row per customer per purchased month
    SELECT
        fs.customer_key,
        fp.cohort_month,
        DATEFROMPARTS(YEAR(cld.date_date), MONTH(cld.date_date), 1) AS order_month
    FROM [dw].[Fact_Sales] fs
    JOIN [dw].[Dim_Calendar] cld ON fs.purchase_date_key = cld.date_key
    JOIN first_purchase fp ON fs.customer_key = fp.customer_key
    GROUP BY fs.customer_key, fp.cohort_month, YEAR(cld.date_date), MONTH(cld.date_date)
),
cohort_index AS (
    -- Level 3: how many months passed by since customer first purchase
    SELECT
        customer_key,
        cohort_month,
        order_month,
        DATEDIFF(MONTH, cohort_month, order_month) AS month_index
    FROM monthly_activity
),
cohort_counts AS (
    -- Level 4: customer count per cohort and month index
    SELECT
        cohort_month,
        month_index,
        COUNT(DISTINCT customer_key) AS active_customers
    FROM cohort_index
    GROUP BY cohort_month, month_index
),
cohort_size AS (
    -- Level 5: original size of each cohort (month_index = 0)
    SELECT cohort_month, active_customers AS cohort_size
    FROM cohort_counts
    WHERE month_index = 0
)

SELECT
    cc.cohort_month,
    cc.month_index,
    cc.active_customers,
    cs.cohort_size,
    ROUND(100.0 * cc.active_customers / cs.cohort_size, 1) AS retention_pct,
    ROUND(100.0 * (1 - (1.0 * cc.active_customers / cs.cohort_size)), 1) AS churn_pct
FROM cohort_counts cc
JOIN cohort_size   cs ON cc.cohort_month = cs.cohort_month;
GO


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
    JOIN [dw].[Dim_Calendar] cld ON fs.purchase_date_key = cld.date_key
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
        -- Ratio between silence and normal cycle (>1 = abnormal)
        ROUND(days_since_purchase / NULLIF(avg_cycle_days, 0), 2) AS silence_ratio,
        -- Score 0-100: proportional to how much silence period exceeds average purchase cycle
        LEAST(
            ROUND((days_since_purchase / NULLIF(avg_cycle_days, 0)) * 50, 0),
            100
        ) AS churn_risk_score,
        -- 4 categories: 
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
    dc.customer_unique_id,
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
JOIN [dw].[Dim_Customers] dc ON cs.customer_key = dc.customer_key;
GO