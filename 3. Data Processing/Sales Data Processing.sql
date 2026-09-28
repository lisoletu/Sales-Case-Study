-- Databricks notebook source
---checking what my raw data looks like
SELECT *
FROM sales.analytics.sales_dataset
LIMIT 10;

--checking my columns and data types 
DESCRIBE sales.analytics.sales_dataset;

--checking number of records
SELECT COUNT(*) AS total_records
FROM sales.analytics.sales_dataset;

---------------------------------------------------------------
--Data Profiling
-------------------------------------------------------------
--checking record count of my columns
SELECT
    COUNT(*) AS total_records,
    COUNT(Date) AS date_count,
    COUNT(Sales) AS sales_count,
    COUNT(`Cost Of Sales`) AS cost_of_sales_count,
    COUNT(`Quantity Sold`) AS quantity_count
FROM sales.analytics.sales_dataset;

--checking for duplicates
SELECT
    Date,
    COUNT(*) AS date_count
FROM sales.analytics.sales_dataset
GROUP BY Date
HAVING COUNT(*) > 1
ORDER BY Date;

--checking Min and Max values to see if theres no negative or zeros
SELECT
    MIN(Sales) AS min_sales,
    MAX(Sales) AS max_sales,
    MIN(`Cost Of Sales`) AS min_cost_of_sales,
    MAX(`Cost Of Sales`) AS max_cost_of_sales,
    MIN(`Quantity Sold`) AS min_quantity_sold,
    MAX(`Quantity Sold`) AS max_quantity_sold
FROM sales.analytics.sales_dataset;

--checking Min and Max Date
SELECT
    MIN(Date) AS first_date,
    MAX(Date) AS last_date
FROM sales.analytics.sales_dataset;

----------------------------------------------------------------------------
--Data Cleaning
---------------------------------------------------------------------------
-- creating clean table with standardized column names
CREATE OR REPLACE TABLE sales.analytics.sales_cleaned AS
SELECT
    Date AS sales_date,
    Sales AS sales,
    `Cost Of Sales` AS cost_of_sales,
    `Quantity Sold` AS quantity_sold
FROM sales.analytics.sales_dataset;

SELECT *
FROM sales.analytics.sales_cleaned
LIMIT 10;

-------------------------------------------------------------------------------
--Date Transformations
------------------------------------------------------------------------------
---extracting year, month,number, quarter, day and day name
SELECT
    sales_date,
    YEAR(sales_date) AS year,
    MONTH(sales_date) AS month_number,
    DATE_FORMAT(sales_date, 'MMMM') AS month,
    QUARTER(sales_date) AS quarter,
    DAY(sales_date) AS day,
    DAYNAME(sales_date) AS day_name
FROM sales.analytics.sales_cleaned;

----------------------------------------------------------------
--pricing transformations
----------------------------------------------------------------

-- Creating Daily Sales Price per Unit column (sales/quantity sold)
SELECT
    sales_date,
    sales,
    quantity_sold,
    ROUND(sales / quantity_sold, 2) AS sales_price_per_unit
FROM sales.analytics.sales_cleaned
LIMIT 10;

-- creating the Daily gross profit column (sales - cost of sales)
SELECT
    sales_date,
    sales,
    cost_of_sales,
    quantity_sold,
    ROUND(sales - cost_of_sales, 2) AS gross_profit
FROM sales.analytics.sales_cleaned
LIMIT 10;

--creating the Daily Gross profit per unit column (gross profit/quantity sold)
SELECT
    sales_date,
    sales,
    cost_of_sales,
    quantity_sold,
    ROUND((sales - cost_of_sales) / quantity_sold, 2) AS gross_profit_per_unit
FROM sales.analytics.sales_cleaned
LIMIT 10;

--creating Daily Gross profit % column (gross profit/sales *100)
SELECT
    sales_date,
    sales,
    cost_of_sales,
    quantity_sold,
    ROUND(((sales - cost_of_sales) / sales) * 100, 2) AS gross_profit_percentage
FROM sales.analytics.sales_cleaned
LIMIT 10;

--creating Daily gross profit % per unit column (gross profit per unit/sales per unit *100)
SELECT
    sales_date,
    ROUND(sales / quantity_sold, 2) AS daily_sales_price_per_unit,
    ROUND((sales - cost_of_sales) / quantity_sold, 2) AS gross_profit_per_unit,
    ROUND(
        (
            ((sales - cost_of_sales) / quantity_sold)
            / (sales / quantity_sold)
        ) * 100,
        2
    ) AS gross_profit_pct_per_unit
FROM sales.analytics.sales_cleaned
LIMIT 10;

