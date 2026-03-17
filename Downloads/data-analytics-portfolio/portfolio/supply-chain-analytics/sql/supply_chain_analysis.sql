-- ============================================================================
-- SUPPLY CHAIN PERFORMANCE ANALYTICS
-- Author: Kawtar Barouti
-- Dataset: DataCo Smart Supply Chain (180K+ orders)
-- Database: SQLite
-- ============================================================================

-- ============================================================================
-- QUERY 1: Late delivery rate by shipping mode and customer segment
-- Purpose: Identify which shipping/segment combinations have the worst performance
-- SQL Features: GROUP BY multi-dimensional, aggregate functions, ROUND
-- ============================================================================

SELECT
    "Shipping Mode",
    "Customer Segment",
    COUNT(*) AS total_orders,
    SUM("Late_delivery_risk") AS late_orders,
    ROUND(100.0 * SUM("Late_delivery_risk") / COUNT(*), 1) AS late_pct,
    ROUND(AVG(delivery_days), 1) AS avg_delivery_days
FROM orders
GROUP BY "Shipping Mode", "Customer Segment"
ORDER BY late_pct DESC;


-- ============================================================================
-- QUERY 2: Top 10 regions with highest delay volume (Window Function)
-- Purpose: Rank regions by total late deliveries to prioritize improvements
-- SQL Features: RANK() OVER(), subquery filtering
-- ============================================================================

SELECT * FROM (
    SELECT
        "Order Region",
        COUNT(*) AS total_orders,
        SUM("Late_delivery_risk") AS late_orders,
        ROUND(100.0 * SUM("Late_delivery_risk") / COUNT(*), 1) AS late_pct,
        ROUND(AVG(delivery_days), 1) AS avg_delivery_days,
        RANK() OVER(ORDER BY SUM("Late_delivery_risk") DESC) AS delay_rank
    FROM orders
    GROUP BY "Order Region"
) ranked
WHERE delay_rank <= 10;


-- ============================================================================
-- QUERY 3: Order volume vs. delay correlation (CASE WHEN segmentation)
-- Purpose: Determine if larger orders experience more delays
-- SQL Features: CASE WHEN bucketing, conditional aggregation
-- ============================================================================

SELECT
    CASE
        WHEN "Order Item Quantity" <= 2 THEN '1. Small (1-2)'
        WHEN "Order Item Quantity" <= 4 THEN '2. Medium (3-4)'
        ELSE '3. Large (5+)'
    END AS order_size,
    COUNT(*) AS total_orders,
    SUM("Late_delivery_risk") AS late_orders,
    ROUND(100.0 * SUM("Late_delivery_risk") / COUNT(*), 1) AS late_pct,
    ROUND(AVG("Sales per customer"), 2) AS avg_sales,
    ROUND(AVG("Order Item Profit Ratio"), 3) AS avg_profit_ratio
FROM orders
GROUP BY order_size
ORDER BY order_size;


-- ============================================================================
-- QUERY 4: Monthly delay evolution (CTE + Time Series)
-- Purpose: Detect seasonal patterns in delivery performance
-- SQL Features: CTE, strftime date extraction, time-series analysis
-- ============================================================================

WITH monthly_stats AS (
    SELECT
        strftime('%Y-%m', order_date) AS month,
        COUNT(*) AS total_orders,
        SUM("Late_delivery_risk") AS late_orders,
        ROUND(AVG(delivery_days), 1) AS avg_delivery_days
    FROM orders
    WHERE order_date IS NOT NULL
    GROUP BY month
)
SELECT
    month,
    total_orders,
    late_orders,
    ROUND(100.0 * late_orders / total_orders, 1) AS late_pct,
    avg_delivery_days
FROM monthly_stats
ORDER BY month;


-- ============================================================================
-- QUERY 5: Profitability vs. delivery performance (advanced)
-- Purpose: Analyze if late deliveries impact profitability
-- SQL Features: Multiple aggregations, conditional metrics
-- ============================================================================

SELECT
    CASE
        WHEN "Late_delivery_risk" = 1 THEN 'Late'
        ELSE 'On Time'
    END AS delivery_status,
    COUNT(*) AS total_orders,
    ROUND(AVG("Sales per customer"), 2) AS avg_sales,
    ROUND(AVG("Order Item Profit Ratio"), 4) AS avg_profit_ratio,
    ROUND(SUM("Order Profit Per Order"), 2) AS total_profit,
    ROUND(AVG("Order Item Discount Rate"), 3) AS avg_discount
FROM orders
GROUP BY delivery_status;


-- ============================================================================
-- QUERY 6: Shipping mode performance ranking per market (Window Function)
-- Purpose: Compare shipping efficiency across different markets
-- SQL Features: RANK() OVER(PARTITION BY), multi-level ranking
-- ============================================================================

SELECT * FROM (
    SELECT
        "Market",
        "Shipping Mode",
        COUNT(*) AS total_orders,
        ROUND(100.0 * SUM("Late_delivery_risk") / COUNT(*), 1) AS late_pct,
        ROUND(AVG(delivery_days), 1) AS avg_days,
        RANK() OVER(
            PARTITION BY "Market"
            ORDER BY 100.0 * SUM("Late_delivery_risk") / COUNT(*) DESC
        ) AS rank_in_market
    FROM orders
    GROUP BY "Market", "Shipping Mode"
) ranked
WHERE rank_in_market <= 3
ORDER BY "Market", rank_in_market;
