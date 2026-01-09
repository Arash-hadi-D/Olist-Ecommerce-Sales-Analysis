/* 
This script validates the Excel Dashboard metrics using Google BigQuery SQL. 
It ensures data integrity for KPIs related to Logistics Performance and Revenue Concentration.

OPERATIONS:
1. ETL & Cleaning: Filters date ranges (2017-2018), removes outliers (>90 days), and handles NULLs.
2. Feature Engineering: Calculates 'Delivery_Days' and flags 'Delivery_Status' (Late vs. On-Time).
3. Analytics:
   - Quantifies the 'Logistics Gap' (impact of delays on Review Scores).
   - Identifies Top 3 Revenue Categories using Window Functions.
*/

/* 
STEP 1: MAIN CTE (Common Table Expression)
- Joins Orders, Items, Products, and Reviews tables.
- Filters for 'delivered' orders within the mature analysis period (Jan 2017 - Aug 2018).
- Removes data quality outliers (delivery > 90 days).
- Creates the 'delivery_status' flag for downstream analysis.
*/

WITH main_table AS (
    SELECT 
        o.order_id,
        o.customer_id,
        o.order_status,
        o.order_purchase_timestamp,
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date,
        
        -- Calculate actual delivery duration in days
        DATE_DIFF(DATE(o.order_delivered_customer_date), DATE(o.order_purchase_timestamp), DAY) AS delivery_days,

        -- Flag orders as 'Late' or 'On Time' based on estimated delivery date
        CASE 
            WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 'Late'
            ELSE 'On Time' 
        END AS delivery_status,

        
        oi.price,
        oi.freight_value,
        p.product_category_name,
        r.review_score
   
    FROM olist_orders_dataset o
    -- Inner Join: Only include orders that generated revenue (have items)
    JOIN olist_order_items_dataset oi ON o.order_id = oi.order_id
   -- Inner Join: Attach product category metadata
    JOIN olist_products_dataset p ON oi.product_id = p.product_id
    -- Left Join: Include all orders even if review is missing (NULL reviews are valid for sales analysis)
    LEFT JOIN olist_order_reviews_dataset r ON o.order_id = r.order_id
   
    WHERE 
        o.order_status = 'delivered'
        And order_purchase_timestamp BETWEEN '2017-01-01' AND '2018-09-01'
        ANd DATE_DIFF(DATE(o.order_delivered_customer_date), DATE(o.order_purchase_timestamp), DAY) <91
)

/* 
STEP 2: LOGISTICS GAP ANALYSIS
- Aggregates metrics by Delivery Status to quantify customer satisfaction impact.
- Uses COUNT(DISTINCT) because order_id duplicates exist due to multiple items per order.
*/
SELECT 
    delivery_status,
    /*i use Distinct with count function because i only want the unique orders  
    (in this dataset oder_id is not unique to be able to show different  product_ids in a order_id)*/
    COUNT(DISTINCT order_id) as total_orders,
    ROUND(AVG(review_score), 2) as avg_score,
    ROUND(AVG(delivery_days), 1) as avg_days_to_deliver
FROM main_table
GROUP BY 1
ORDER BY 1 DESC;


/* 
STEP 3: REVENUE CONCENTRATION (PARETO ANALYSIS)
- Identifies Top 3 categories driving revenue.
- Uses Window Functions (RANK) to handle ties robustly.
- Uses COALESCE to handle missing English translations.
*/
SELECT * FROM (
    SELECT 
      COALESCE(t.product_category_name_english, 'Unknown') AS top_3_categories,
      SUM(price) AS total_revenue,
      -- Window Function to rank categories by revenue
      RANK() OVER (ORDER BY SUM(price) DESC) as revenue_rank
    FROM main_table 
    -- Left join to get English names, keeping all revenue-generating rows
    LEFT JOIN product_category_name_translation t 
        ON main_table.product_category_name = t.product_category_name
    GROUP BY 1
) 
WHERE revenue_rank <= 3;


--end of script


