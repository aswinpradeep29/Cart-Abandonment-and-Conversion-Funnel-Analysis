-- Query 1: Monthly event counts
SELECT
    DATE_FORMAT(event_time, '%Y-%m') AS month,
    event_type,
    COUNT(*) AS event_count
FROM ecommerce_events
GROUP BY
    DATE_FORMAT(event_time, '%Y-%m'),
    event_type
ORDER BY
    month,
    event_type;
    
-- Query 2: Monthly distinct sessions by event type
SELECT
    DATE_FORMAT(event_time, '%Y-%m') AS month,
    event_type,
    COUNT(DISTINCT user_session) AS sessions
FROM ecommerce_events
WHERE user_session IS NOT NULL
GROUP BY
    DATE_FORMAT(event_time, '%Y-%m'),
    event_type
ORDER BY
    month,
    event_type;
    
-- Query 3: Overall session funnel counts and conversion rates
SELECT
    COUNT(*) AS total_sessions,
    SUM(had_view = 1) AS sessions_with_view,
    SUM(had_cart = 1) AS sessions_with_cart,
    SUM(had_purchase = 1) AS sessions_with_purchase,
    SUM(had_cart = 1 AND had_purchase = 1) AS cart_sessions_that_purchased,
    SUM(had_cart = 1 AND had_purchase = 0) AS abandoned_cart_sessions,
    ROUND(
        100.0 * SUM(had_cart = 1) / SUM(had_view = 1),
        2
    ) AS view_to_cart_rate_pct,
    ROUND(
        100.0 * SUM(had_cart = 1 AND had_purchase = 1) / SUM(had_cart = 1),
        2
    ) AS cart_to_purchase_rate_pct,
    ROUND(
        100.0 * SUM(had_cart = 1 AND had_purchase = 0) / SUM(had_cart = 1),
        2
    ) AS cart_abandonment_rate_pct
FROM sessions;

-- Query 4: Monthly cart abandonment
SELECT
    DATE_FORMAT(session_start, '%Y-%m') AS month,
    COUNT(*) AS cart_sessions,
    SUM(had_purchase = 1) AS cart_sessions_that_purchased,
    SUM(had_purchase = 0) AS abandoned_cart_sessions,
    ROUND(
        100.0 * SUM(had_purchase = 0) / COUNT(*),
        2
    ) AS cart_abandonment_rate_pct
FROM sessions
WHERE had_cart = 1
GROUP BY DATE_FORMAT(session_start, '%Y-%m')
ORDER BY month;

-- Query 5: Monthly session funnel rates
SELECT
    DATE_FORMAT(session_start, '%Y-%m') AS month,
    SUM(had_view = 1) AS view_sessions,
    SUM(had_cart = 1) AS cart_sessions,
    SUM(had_cart = 1 AND had_purchase = 1) AS cart_sessions_that_purchased,
    ROUND(
        100.0 * SUM(had_cart = 1) / SUM(had_view = 1),
        2
    ) AS view_to_cart_rate_pct,
    ROUND(
        100.0 * SUM(had_cart = 1 AND had_purchase = 1) / SUM(had_cart = 1),
        2
    ) AS cart_to_purchase_rate_pct,
    ROUND(
        100.0 * SUM(had_cart = 1 AND had_purchase = 0) / SUM(had_cart = 1),
        2
    ) AS cart_abandonment_rate_pct
FROM sessions
GROUP BY DATE_FORMAT(session_start, '%Y-%m')
ORDER BY month;

-- Query 6: Top brands by purchase events
SELECT
    brand,
    COUNT(*) AS purchase_events
FROM ecommerce_events
WHERE event_type = 'purchase'
  AND brand IS NOT NULL
GROUP BY brand
ORDER BY purchase_events DESC
LIMIT 10;

-- Query 7: Monthly purchase event value
SELECT
    DATE_FORMAT(event_time, '%Y-%m') AS month,
    COUNT(*) AS purchase_events,
    ROUND(SUM(price), 2) AS recorded_purchase_value
FROM ecommerce_events
WHERE event_type = 'purchase'
GROUP BY DATE_FORMAT(event_time, '%Y-%m')
ORDER BY month;

-- Query 8: Average recorded price by month and event type
SELECT
    DATE_FORMAT(event_time, '%Y-%m') AS month,
    event_type,
    COUNT(*) AS event_rows,
    ROUND(AVG(price), 2) AS average_recorded_price
FROM ecommerce_events
GROUP BY
    DATE_FORMAT(event_time, '%Y-%m'),
    event_type
ORDER BY
    month,
    event_type;
    
-- Query 9: Top 10 categories by purchase events
SELECT
    category_id,
    category_code,
    COUNT(*) AS purchase_events,
    ROUND(SUM(price), 2) AS recorded_purchase_value
FROM ecommerce_events
WHERE event_type = 'purchase'
GROUP BY
    category_id,
    category_code
ORDER BY purchase_events DESC
LIMIT 10;

-- Query 10: Rank brands by purchase events within each month
WITH monthly_brand_purchases AS (
    SELECT
        DATE_FORMAT(event_time, '%Y-%m') AS month,
        brand,
        COUNT(*) AS purchase_events
    FROM ecommerce_events
    WHERE event_type = 'purchase'
      AND brand IS NOT NULL
    GROUP BY
        DATE_FORMAT(event_time, '%Y-%m'),
        brand
),
ranked_brands AS (
    SELECT
        month,
        brand,
        purchase_events,
        RANK() OVER (
            PARTITION BY month
            ORDER BY purchase_events DESC
        ) AS brand_rank
    FROM monthly_brand_purchases
)
SELECT
    month,
    brand,
    purchase_events,
    brand_rank
FROM ranked_brands
WHERE brand_rank <= 5
ORDER BY
    month,
    brand_rank;
    
-- Query 11: Session counts by event type, joined to session summary
SELECT
    e.event_type,
    COUNT(DISTINCT e.user_session) AS sessions_with_event,
    COUNT(DISTINCT CASE WHEN s.had_cart = 1 THEN e.user_session END) AS cart_sessions,
    COUNT(DISTINCT CASE WHEN s.had_purchase = 1 THEN e.user_session END) AS purchase_sessions
FROM ecommerce_events AS e
LEFT JOIN sessions AS s
    ON e.user_session = s.user_session
WHERE e.user_session IS NOT NULL
GROUP BY e.event_type
ORDER BY e.event_type;