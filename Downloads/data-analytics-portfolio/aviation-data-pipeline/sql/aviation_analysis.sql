-- ============================================================================
-- AVIATION FLIGHT DELAY ANALYTICS
-- Author: Kawtar Barouti
-- Dataset: Flight Delay & Cancellation 2019-2023
-- Database: SQLite (star schema from ETL pipeline)
-- ============================================================================


-- ============================================================================
-- QUERY 1: Airline Performance Ranking (Window Function)
-- Purpose: Rank airlines by average delay and on-time performance
-- SQL Features: RANK() OVER(), CASE WHEN aggregation
-- ============================================================================

SELECT
    AIRLINE,
    COUNT(*) AS total_flights,
    ROUND(AVG(ARR_DELAY), 1) AS avg_delay_min,
    ROUND(100.0 * SUM(CASE WHEN ARR_DELAY <= 0 THEN 1 ELSE 0 END)
          / COUNT(*), 1) AS on_time_pct,
    ROUND(100.0 * SUM(CASE WHEN ARR_DELAY > 15 THEN 1 ELSE 0 END)
          / COUNT(*), 1) AS delayed_pct,
    ROUND(100.0 * SUM(CASE WHEN CANCELLED = 1 THEN 1 ELSE 0 END)
          / COUNT(*), 1) AS cancel_pct,
    RANK() OVER(ORDER BY AVG(ARR_DELAY) ASC) AS performance_rank
FROM fact_flights
WHERE ARR_DELAY IS NOT NULL
GROUP BY AIRLINE
HAVING total_flights > 10000
ORDER BY performance_rank;


-- ============================================================================
-- QUERY 2: Top 20 Most Delayed Routes
-- Purpose: Identify the most problematic origin-destination pairs
-- SQL Features: String concatenation, HAVING filter, multiple aggregates
-- ============================================================================

SELECT
    ORIGIN || ' → ' || DEST AS route,
    COUNT(*) AS total_flights,
    ROUND(AVG(ARR_DELAY), 1) AS avg_delay_min,
    ROUND(100.0 * SUM(CASE WHEN ARR_DELAY > 15 THEN 1 ELSE 0 END)
          / COUNT(*), 1) AS delayed_pct,
    ROUND(100.0 * SUM(CASE WHEN CANCELLED = 1 THEN 1 ELSE 0 END)
          / COUNT(*), 1) AS cancel_pct,
    MAX(ARR_DELAY) AS max_delay_min
FROM fact_flights
GROUP BY route
HAVING total_flights > 1000
ORDER BY avg_delay_min DESC
LIMIT 20;


-- ============================================================================
-- QUERY 3: Seasonal Delay Analysis (CTE)
-- Purpose: Detect seasonal patterns — when are delays worst?
-- SQL Features: CTE, CASE WHEN season mapping, seasonal aggregation
-- ============================================================================

WITH seasonal AS (
    SELECT
        month,
        CASE
            WHEN month IN (12, 1, 2) THEN 'Winter'
            WHEN month IN (3, 4, 5) THEN 'Spring'
            WHEN month IN (6, 7, 8) THEN 'Summer'
            ELSE 'Fall'
        END AS season,
        ARR_DELAY,
        is_delayed,
        CANCELLED
    FROM fact_flights
    WHERE ARR_DELAY IS NOT NULL
)
SELECT
    season,
    COUNT(*) AS total_flights,
    ROUND(AVG(ARR_DELAY), 1) AS avg_delay_min,
    ROUND(100.0 * SUM(is_delayed) / COUNT(*), 1) AS delayed_pct,
    ROUND(100.0 * SUM(CANCELLED) / COUNT(*), 1) AS cancel_pct
FROM seasonal
GROUP BY season
ORDER BY avg_delay_min DESC;


-- ============================================================================
-- QUERY 4: Day of Week × Hour Analysis (Heatmap data)
-- Purpose: Find the worst day/time combinations for delays
-- SQL Features: Multi-dimensional GROUP BY, time bucketing
-- ============================================================================

SELECT
    day_name,
    day_of_week,
    CASE
        WHEN CAST(CRS_DEP_TIME AS INTEGER) / 100 BETWEEN 0 AND 5 THEN 'Night (0-5h)'
        WHEN CAST(CRS_DEP_TIME AS INTEGER) / 100 BETWEEN 6 AND 11 THEN 'Morning (6-11h)'
        WHEN CAST(CRS_DEP_TIME AS INTEGER) / 100 BETWEEN 12 AND 17 THEN 'Afternoon (12-17h)'
        ELSE 'Evening (18-23h)'
    END AS time_slot,
    COUNT(*) AS flights,
    ROUND(AVG(ARR_DELAY), 1) AS avg_delay,
    ROUND(100.0 * SUM(is_delayed) / COUNT(*), 1) AS delayed_pct
FROM fact_flights
WHERE ARR_DELAY IS NOT NULL
  AND CRS_DEP_TIME IS NOT NULL
GROUP BY day_name, day_of_week, time_slot
ORDER BY day_of_week, time_slot;


-- ============================================================================
-- QUERY 5: Year-over-Year Trend with COVID Impact
-- Purpose: Track how delays evolved 2019-2023, including pandemic effect
-- SQL Features: Year aggregation, YoY comparison with LAG()
-- ============================================================================

WITH yearly AS (
    SELECT
        year,
        COUNT(*) AS total_flights,
        ROUND(AVG(CASE WHEN ARR_DELAY IS NOT NULL THEN ARR_DELAY END), 1) AS avg_delay,
        SUM(CASE WHEN is_delayed = 1 THEN 1 ELSE 0 END) AS delayed_flights,
        SUM(CASE WHEN CANCELLED = 1 THEN 1 ELSE 0 END) AS cancelled_flights
    FROM fact_flights
    GROUP BY year
)
SELECT
    year,
    total_flights,
    avg_delay,
    ROUND(100.0 * delayed_flights / total_flights, 1) AS delayed_pct,
    ROUND(100.0 * cancelled_flights / total_flights, 1) AS cancel_pct,
    LAG(total_flights) OVER(ORDER BY year) AS prev_year_flights,
    ROUND(100.0 * (total_flights - LAG(total_flights) OVER(ORDER BY year))
          / LAG(total_flights) OVER(ORDER BY year), 1) AS yoy_flight_change_pct
FROM yearly
ORDER BY year;


-- ============================================================================
-- QUERY 6: Busiest Airports — Origin Analysis
-- Purpose: Identify airports with highest traffic and worst delay performance
-- SQL Features: RANK() with PARTITION, airport-level aggregation
-- ============================================================================

SELECT
    ORIGIN AS airport,
    COUNT(*) AS departures,
    ROUND(AVG(ARR_DELAY), 1) AS avg_delay,
    ROUND(100.0 * SUM(is_delayed) / COUNT(*), 1) AS delayed_pct,
    ROUND(100.0 * SUM(CANCELLED) / COUNT(*), 1) AS cancel_pct,
    RANK() OVER(ORDER BY COUNT(*) DESC) AS traffic_rank,
    RANK() OVER(ORDER BY AVG(ARR_DELAY) DESC) AS delay_rank
FROM fact_flights
WHERE ARR_DELAY IS NOT NULL
GROUP BY ORIGIN
HAVING departures > 5000
ORDER BY traffic_rank
LIMIT 30;
