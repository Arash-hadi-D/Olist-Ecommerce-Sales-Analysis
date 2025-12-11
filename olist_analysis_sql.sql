/* 
This script validates the Excel Dashboard logic using Google BigQuery SQL. you will read steps which 
help you to get Logistics gap stats, Top 3 categories in revenue(price).
It performs the following operations:
1. ETL & Data Cleaning (Filtering dates, removing outliers).
2. Feature Engineering (Delivery Days, Delivery Status).
3. Metric Calculation (Logistics Gap, Top 3 Revenue Categories).
*/


/*in the first step i join the tables then do the necessary data cleaning, filtering and create flags for delivery status also
calculate the delivery days to have a final Table with all the necessary data needed to get insights from. this dataset is mostly 
clean but there are some null observations which needs to be addressed. we can do this step by using a CTE.
*/

WITH main_table AS (
    SELECT 
        o.order_id,
        o.customer_id,
        o.order_status,
        o.order_purchase_timestamp,
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date,
        
        -- Feature engineering the Delivery Days
        DATE_DIFF(DATE(o.order_delivered_customer_date), DATE(o.order_purchase_timestamp), DAY) AS delivery_days,

        -- flaging orders by Delivery Status (On Time/Late)
        CASE 
            WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 'Late'
            ELSE 'On Time' 
        END AS delivery_status,

        
        oi.price,
        oi.freight_value,
        p.product_category_name,
        
        
        r.review_score
    -- first i inner join the orders with order items to get only the orders that have items in it(made revenue).
    FROM olist_orders_dataset o
    JOIN olist_order_items_dataset oi ON o.order_id = oi.order_id
    --here i do the same with the product dataset to be able to get the product categories for orders
    JOIN olist_products_dataset p ON oi.product_id = p.product_id
    --here i left join the results with reviews dataset (i want all of the orders even the ones that doesn't have reviews) to be able to get review scores
    LEFT JOIN olist_order_reviews_dataset r ON o.order_id = r.order_id
    /*here i filter(exclude) orders that are not delivered(only including orders that made revenue), orders made in 2016(gap in collection) and before September
    of 2018(incomplete collection) and outliers of delivery days more than 90(which are probably lost Packages or data entry errors)
    */
    WHERE 
        o.order_status = 'delivered'
        And order_purchase_timestamp BETWEEN '2017-01-01' AND '2018-09-01'
        ANd DATE_DIFF(DATE(o.order_delivered_customer_date), DATE(o.order_purchase_timestamp), DAY) <91
)

--please note that i changed the address of my tables in this code, to make it easier to reproduce.


-- now i can use the CTE i created above to get my insights

-- this querry Calculates the impact of late deliveries on customer satisfaction.
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


--  here i calculate the top 3 Categories by revenue
SELECT 
  COALESCE(t.product_category_name_english, 'Unknown') AS top_3_categories,
  SUM(price) AS total_revenue
FROM main_table 
--here i use left join because i need all the rows(they made revenue) even the ones that are not translated
LEFT JOIN product_category_name_translation t ON product_category_name = t.product_category_name
GROUP BY 1
ORDER BY 2 DESC 
limit 3;


--end of script
