

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
    JOIN [dw].[Dim_Data] cld ON fs.data_compra_key = cld.data_key
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