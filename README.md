#  Olist E-Commerce Brazilian Sales Analysis

![Dashboard Preview](dashboard_overview.jpg)
*Snapshot of the Interactive Dashboard (Excel)*

##  Executive Summary
This project analyzes **100k+ anonymized orders** from Olist, a Brazilian e-commerce marketplace, to identify sales trends, logistics performance, and revenue drivers. 

Using **Microsoft Excel**, I transformed raw relational data into an interactive dashboard. The analysis focuses on the "Mature Operations" phase (Jan 2017 – Aug 2018), filtering out early pilot data and incomplete collection periods to ensure statistical accuracy.

**Key Achievement:** Identified a critical "Logistics Gap" where a 20-day delay in delivery correlates with a 1.6-star drop in customer satisfaction.


##  About the Dataset
The data was sourced from the **[Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)** on Kaggle. 
*   **Description:** This is real commercial data (anonymized) comprising 100,000 orders made at multiple marketplaces in Brazil.
*   **Scope:** It connects the order lifecycle from purchase to delivery, including customer reviews, seller location, product attributes, and geolocation data.
    * Tables: 9 (Relational CSVs including Orders, Customers, Reviews, Products)
    * Rows: 99,441 Orders (before filtering)
*   **Timeline:** 2016 to 2018 (Analysis focuses on the 2017-2018 mature period).



##  Tools & Strategy
*   **Data Cleaning (Power Query):** Merged multiple relational tables (Orders, Reviews, Customers, Geolocation, Products) and standardized data types.
*   **Feature Engineering:** Created custom metrics including `Delivery_Time_Days`, `Delivery_Status` (On-Time vs. Late), and `Category_Groups`(reducing 74 Categories to 14 Category_groups).
*   **Data Modeling:** Utilized Pivot Tables and Data Models to aggregate millions of data points into dynamic KPIs.
*   **Visualization:** Designed a professional dynamic Dashboard using Slicers, Linked Pictures, and Geographic Heat Maps.

##  Key Findings

### 1. Revenue Concentration
The business relies heavily on a few core segments. The top three macro-categories (**Health & Beauty**, **Watches & Gifts**, and **Bed, Bath & Table**) generated approximately **26%** of the grand total revenue during the analyzed timeline. This indicates a strong market fit in these specific niches but exposes the business to risk if these specific categories underperform.

### 2. The "Logistics Gap"
Analysis reveals a sharp contrast in customer satisfaction based on delivery performance. 
*   **On-time deliveries:** Average Review Score of **4.16/5** (Avg delivery time: 10.4 days).
*   **Delayed deliveries:** Average Review Score plummets to **2.55/5** (Avg delivery time: 30.9 days).
*   **Impact:** This confirms a strong negative correlation: a ~20-day increase in delivery time effectively costs the business 1.6 stars in customer satisfaction.

### 3. Monthly Revenue Trend
The sales data displays a clear upward trend from Jan 2017 to Aug 2018, with a distinct peak in November, likely driven by Black Friday promotions. However, there is a notable seasonal pattern showing a sales decline of **almost 14% from May to June** in both 2017 and 2018, which requires further root cause analysis to mitigate future Q2 slumps.

##  Recommendations

1.  **Optimize "Last Mile" Logistics:** Olist should Investigate carrier performance in states with the highest "Late Delivery" rates and or develop a predictive SLA breach algorithm. Reducing late deliveries by just 50% could potentially increase the overall Average Review Score, driving higher customer trust and repeat purchases.

2.  **Targeted Inventory Focus:** Prioritizing stock availability and supplier relationships specifically for **Health & Beauty**, **Watches & Gifts**, and **Bed, Bath & Table** to prevent stockouts in these critical segments.

3.  **Seasonal Retention Strategy:** Launching a dedicated "Post-May" investigation task force. If no concrete result was found, counter it with mid-year promotions or loyalty incentives.

---
###  Project Structure
*   **[Download Project File (Excel)](https://docs.google.com/spreadsheets/d/10fxGrWl1Hgm6WK1cin0v4wGfU9LSxsBL/edit?usp=sharing&ouid=116764094025151136870&rtpof=true&sd=true)**: The complete Excel model (Hosted on Google Drive due to GitHub size limits).
*   `dashboard_overview.jpg`: preview of the final output.



