/*
Olist delivery and satisfaction: BigQuery validation of the v2 model

This script rebuilds the v2 figures straight from the raw Olist tables, as an
independent check on the star schema behind the Tableau and Power BI dashboards.
Each query lists the result it should return, so any difference shows up at once.

Source tables: six of the nine Kaggle files, loaded into the BigQuery dataset
daring-blend-408819.olist under their file names without .csv:
  olist_orders_dataset, olist_order_items_dataset, olist_order_reviews_dataset,
  olist_customers_dataset, olist_products_dataset, product_category_name_translation
To run it in another project, replace daring-blend-408819.olist with your own project.dataset.
Payments, sellers and geolocation are not part of the model and are not needed.
product_category_name_translation needs its real column names. BigQuery's auto detect
can't find the header in an all-text file and names the columns string_field_0 and _1.

Rules (same as the Metric definitions table in the README):
  Order          one order_id with status 'delivered', purchased January 2017 to August 2018
  Delivery time  purchase to customer delivery in fractional days, capped below 91 days
  Late           delivered after the promised calendar day
  Review score   one score per order; an order with several reviews uses their mean
  Revenue        price + freight_value, summed over the order's items, in R$
  State          each customer's state on their most recent order (same as Dim_Customer)

Run the whole script in one go in the BigQuery console. Every SELECT gets its own
result tab.
*/

/*
STEP 1: ONE ROW PER ORDER
The v1 script joined orders to order items before averaging, so an order with four
items counted four times in every average. Reviews and revenue are now collapsed to
one row per order first, and the joins happen at order grain.
*/
CREATE TEMP TABLE orders_v2 AS
WITH order_reviews AS (
    -- Some orders have more than one review; their mean keeps each order to one score
    SELECT order_id, AVG(review_score) AS review_score
    FROM `daring-blend-408819.olist.olist_order_reviews_dataset`
    GROUP BY order_id
),
order_revenue AS (
    SELECT order_id, SUM(price + freight_value) AS revenue
    FROM `daring-blend-408819.olist.olist_order_items_dataset`
    GROUP BY order_id
),
customer_latest_state AS (
    -- One state per customer: the state on their most recent order
    SELECT customer_unique_id, customer_state
    FROM (
        SELECT
            c.customer_unique_id,
            c.customer_state,
            ROW_NUMBER() OVER (
                PARTITION BY c.customer_unique_id
                ORDER BY o.order_purchase_timestamp DESC
            ) AS order_recency
        FROM `daring-blend-408819.olist.olist_orders_dataset` o
        JOIN `daring-blend-408819.olist.olist_customers_dataset` c ON o.customer_id = c.customer_id
    )
    WHERE order_recency = 1
)
SELECT
    o.order_id,
    s.customer_state,
    TIMESTAMP_DIFF(o.order_delivered_customer_date, o.order_purchase_timestamp, SECOND) / 86400 AS delivery_days,
    -- Calendar day rule: arriving on the promised day counts as on time, whatever the clock says
    DATE(o.order_delivered_customer_date) > DATE(o.order_estimated_delivery_date) AS is_late,
    r.review_score,
    rev.revenue
FROM `daring-blend-408819.olist.olist_orders_dataset` o
JOIN `daring-blend-408819.olist.olist_customers_dataset` c ON o.customer_id = c.customer_id
JOIN customer_latest_state s ON c.customer_unique_id = s.customer_unique_id
JOIN order_revenue rev ON o.order_id = rev.order_id
-- Left join keeps the 639 delivered orders that never received a review
LEFT JOIN order_reviews r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
    AND o.order_delivered_customer_date IS NOT NULL
    AND o.order_purchase_timestamp >= '2017-01-01'
    AND o.order_purchase_timestamp < '2018-09-01'
    AND TIMESTAMP_DIFF(o.order_delivered_customer_date, o.order_purchase_timestamp, SECOND) / 86400 < 91;


/*
STEP 2: HEADLINE FIGURES
Expected: 96,127 orders | average review 4.16 | 6,455 late orders | late rate 6.7%
          r = -0.35 between delivery days and review score, on 95,488 reviewed orders
*/
SELECT
    COUNT(*) AS orders,
    ROUND(AVG(review_score), 2) AS avg_review_score,
    COUNTIF(is_late) AS late_orders,
    ROUND(100 * COUNTIF(is_late) / COUNT(*), 1) AS late_rate_pct,
    ROUND(CORR(delivery_days, review_score), 2) AS r_delivery_days_vs_review,
    COUNT(review_score) AS orders_with_review
FROM orders_v2;


/*
STEP 3: ON TIME VS LATE
Expected: On time  89,672 orders | review 4.29 | 11.0 days | 6.6% one-star
          Late      6,455 orders | review 2.27 | 32.7 days | 53.8% one-star
One-star share is out of orders that have a review.
*/
SELECT
    IF(is_late, 'Late', 'On time') AS delivery_status,
    COUNT(*) AS orders,
    ROUND(AVG(review_score), 2) AS avg_review_score,
    ROUND(AVG(delivery_days), 1) AS avg_delivery_days,
    ROUND(100 * COUNTIF(review_score = 1) / COUNT(review_score), 1) AS one_star_pct
FROM orders_v2
GROUP BY delivery_status
ORDER BY delivery_status DESC;


/*
STEP 4: LATE RATE BY STATE, TOP 15 STATES BY REVENUE
Expected: the 15 states reach 94.6% of revenue in the last row of cumulative_share_pct;
          late rates run from 4.0% (PR) to 17.3% (MA); SP is 37.5% of revenue at 4.5% late
*/
SELECT
    revenue_rank,
    customer_state,
    ROUND(revenue, 0) AS revenue_brl,
    ROUND(100 * revenue_share, 1) AS revenue_share_pct,
    ROUND(100 * SUM(revenue_share) OVER (ORDER BY revenue_rank), 1) AS cumulative_share_pct,
    ROUND(100 * late_rate, 1) AS late_rate_pct,
    ROUND(avg_review_score, 2) AS avg_review_score
FROM (
    SELECT
        customer_state,
        SUM(revenue) AS revenue,
        SUM(revenue) / SUM(SUM(revenue)) OVER () AS revenue_share,
        COUNTIF(is_late) / COUNT(*) AS late_rate,
        AVG(review_score) AS avg_review_score,
        RANK() OVER (ORDER BY SUM(revenue) DESC) AS revenue_rank
    FROM orders_v2
    GROUP BY customer_state
)
WHERE revenue_rank <= 15
ORDER BY revenue_rank;


/*
STEP 5: TOP 3 PRODUCT CATEGORIES BY REVENUE (raw categories, not the 14 groups)
Expected: health_beauty, watches_gifts, bed_bath_table
Revenue is summed at item level here, because category belongs to the item, not the order.
*/
SELECT
    revenue_rank,
    category,
    ROUND(revenue, 0) AS revenue_brl,
    ROUND(100 * revenue_share, 1) AS revenue_share_pct
FROM (
    SELECT
        -- Two categories have no English translation; they keep their Portuguese name
        COALESCE(t.product_category_name_english, p.product_category_name, 'Unknown') AS category,
        SUM(i.price + i.freight_value) AS revenue,
        SUM(i.price + i.freight_value) / SUM(SUM(i.price + i.freight_value)) OVER () AS revenue_share,
        RANK() OVER (ORDER BY SUM(i.price + i.freight_value) DESC) AS revenue_rank
    FROM `daring-blend-408819.olist.olist_order_items_dataset` i
    JOIN orders_v2 o ON i.order_id = o.order_id
    JOIN `daring-blend-408819.olist.olist_products_dataset` p ON i.product_id = p.product_id
    LEFT JOIN `daring-blend-408819.olist.product_category_name_translation` t ON p.product_category_name = t.product_category_name
    GROUP BY category
)
WHERE revenue_rank <= 3
ORDER BY revenue_rank;

-- End of script
