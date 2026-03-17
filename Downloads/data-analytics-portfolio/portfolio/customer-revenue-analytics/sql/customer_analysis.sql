-- ============================================================================
-- CUSTOMER & REVENUE ANALYTICS
-- Author: Kawtar Barouti
-- Dataset: Brazilian E-Commerce (Olist) — 8 relational tables, 100K+ orders
-- Database: SQLite
-- ============================================================================


-- ============================================================================
-- QUERY 1: Complete RFM Segmentation (Recency, Frequency, Monetary)
-- Purpose: Score and segment customers by purchasing behavior
-- SQL Features: CTE, NTILE() window function, CASE WHEN, multi-table JOIN
-- ============================================================================

WITH rfm AS (
    SELECT
        c.customer_unique_id,
        CAST(julianday('2018-10-01') - julianday(MAX(o.order_purchase_timestamp))
             AS INTEGER) AS recency,
        COUNT(DISTINCT o.order_id) AS frequency,
        ROUND(SUM(p.payment_value), 2) AS monetary
    FROM olist_customers_dataset c
    JOIN olist_orders_dataset o ON c.customer_id = o.customer_id
    JOIN olist_order_payments_dataset p ON o.order_id = p.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
scored AS (
    SELECT *,
        NTILE(5) OVER(ORDER BY recency ASC) AS r_score,
        NTILE(5) OVER(ORDER BY frequency DESC) AS f_score,
        NTILE(5) OVER(ORDER BY monetary DESC) AS m_score
    FROM rfm
)
SELECT *,
    r_score * 100 + f_score * 10 + m_score AS rfm_combined,
    CASE
        WHEN r_score >= 4 AND f_score >= 4 THEN 'Champions'
        WHEN r_score >= 3 AND f_score >= 3 THEN 'Loyal Customers'
        WHEN r_score >= 4 AND f_score <= 2 THEN 'New Customers'
        WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk'
        WHEN r_score <= 2 AND f_score <= 2 THEN 'Lost'
        ELSE 'Potential Loyalists'
    END AS segment
FROM scored;


-- ============================================================================
-- QUERY 2: Revenue Concentration — Pareto Analysis (80/20 Rule)
-- Purpose: Verify if a small % of customers generates majority of revenue
-- SQL Features: Cumulative SUM() OVER(), ROW_NUMBER(), percentage calculation
-- ============================================================================

WITH customer_revenue AS (
    SELECT
        c.customer_unique_id,
        ROUND(SUM(p.payment_value), 2) AS total_revenue
    FROM olist_customers_dataset c
    JOIN olist_orders_dataset o ON c.customer_id = o.customer_id
    JOIN olist_order_payments_dataset p ON o.order_id = p.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
ranked AS (
    SELECT
        customer_unique_id,
        total_revenue,
        ROW_NUMBER() OVER(ORDER BY total_revenue DESC) AS rn,
        COUNT(*) OVER() AS total_customers,
        SUM(total_revenue) OVER(ORDER BY total_revenue DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumul_revenue,
        SUM(total_revenue) OVER() AS grand_total
    FROM customer_revenue
)
SELECT
    rn,
    ROUND(100.0 * rn / total_customers, 1) AS pct_customers,
    total_revenue,
    ROUND(cumul_revenue, 2) AS cumul_revenue,
    ROUND(100.0 * cumul_revenue / grand_total, 1) AS pct_revenue_cumul
FROM ranked
ORDER BY rn;


-- ============================================================================
-- QUERY 3: Revenue & Satisfaction by Product Category (Top 20)
-- Purpose: Identify best-selling categories and their customer satisfaction
-- SQL Features: Multi-table JOIN (4 tables), aggregate functions, LIMIT
-- ============================================================================

SELECT
    pr.product_category_name,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    ROUND(AVG(oi.price), 2) AS avg_price,
    ROUND(SUM(oi.price), 2) AS total_revenue,
    ROUND(AVG(r.review_score), 2) AS avg_review_score,
    COUNT(DISTINCT c.customer_unique_id) AS unique_customers
FROM olist_order_items_dataset oi
JOIN olist_products_dataset pr ON oi.product_id = pr.product_id
JOIN olist_orders_dataset o ON oi.order_id = o.order_id
JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
LEFT JOIN olist_order_reviews_dataset r ON oi.order_id = r.order_id
WHERE o.order_status = 'delivered'
GROUP BY pr.product_category_name
ORDER BY total_revenue DESC
LIMIT 20;


-- ============================================================================
-- QUERY 4: Cohort Analysis — Monthly Retention
-- Purpose: Track customer retention from first purchase month
-- SQL Features: CTE, date extraction, self-join logic, retention calculation
-- ============================================================================

WITH first_purchase AS (
    SELECT
        c.customer_unique_id,
        strftime('%Y-%m', MIN(o.order_purchase_timestamp)) AS cohort_month
    FROM olist_customers_dataset c
    JOIN olist_orders_dataset o ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
orders_with_cohort AS (
    SELECT
        c.customer_unique_id,
        fp.cohort_month,
        strftime('%Y-%m', o.order_purchase_timestamp) AS order_month
    FROM olist_customers_dataset c
    JOIN olist_orders_dataset o ON c.customer_id = o.customer_id
    JOIN first_purchase fp ON c.customer_unique_id = fp.customer_unique_id
    WHERE o.order_status = 'delivered'
)
SELECT
    cohort_month,
    COUNT(DISTINCT customer_unique_id) AS cohort_size,
    COUNT(DISTINCT CASE WHEN order_month > cohort_month THEN customer_unique_id END) AS returned,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN order_month > cohort_month THEN customer_unique_id END)
          / COUNT(DISTINCT customer_unique_id), 1) AS retention_pct
FROM orders_with_cohort
GROUP BY cohort_month
HAVING cohort_size >= 100
ORDER BY cohort_month;


-- ============================================================================
-- QUERY 5: Geographic Revenue Distribution (by State)
-- Purpose: Identify highest-revenue and highest-volume regions
-- SQL Features: GROUP BY with geographic dimension, ranking
-- ============================================================================

SELECT
    c.customer_state,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT c.customer_unique_id) AS unique_customers,
    ROUND(SUM(p.payment_value), 2) AS total_revenue,
    ROUND(AVG(p.payment_value), 2) AS avg_order_value,
    RANK() OVER(ORDER BY SUM(p.payment_value) DESC) AS revenue_rank
FROM olist_customers_dataset c
JOIN olist_orders_dataset o ON c.customer_id = o.customer_id
JOIN olist_order_payments_dataset p ON o.order_id = p.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY revenue_rank;


-- ============================================================================
-- QUERY 6: Monthly Revenue Trend with MoM Growth
-- Purpose: Track revenue evolution and identify growth/decline periods
-- SQL Features: LAG() window function for period-over-period comparison
-- ============================================================================

WITH monthly_revenue AS (
    SELECT
        strftime('%Y-%m', o.order_purchase_timestamp) AS month,
        ROUND(SUM(p.payment_value), 2) AS revenue,
        COUNT(DISTINCT o.order_id) AS orders
    FROM olist_orders_dataset o
    JOIN olist_order_payments_dataset p ON o.order_id = p.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY month
)
SELECT
    month,
    revenue,
    orders,
    LAG(revenue) OVER(ORDER BY month) AS prev_month_revenue,
    ROUND(100.0 * (revenue - LAG(revenue) OVER(ORDER BY month))
          / LAG(revenue) OVER(ORDER BY month), 1) AS mom_growth_pct
FROM monthly_revenue
ORDER BY month;
