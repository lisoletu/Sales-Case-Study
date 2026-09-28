-- Databricks notebook source
CREATE OR REPLACE TABLE sales.analytics.sales_final AS

WITH transformed_data AS (

    SELECT
        sales_date,
        CAST(ROUND(sales) AS DECIMAL (10,2)) AS sales,
        CAST(ROUND(cost_of_sales) AS DECIMAL (10,2)) AS cost_of_sales,
        quantity_sold,
        YEAR(sales_date) AS year,
        MONTH(sales_date) AS month_number,
        DATE_FORMAT(sales_date, 'MMMM') AS month,
        QUARTER(sales_date) AS quarter,
        DAY(sales_date) AS day,
        DAYNAME(sales_date) AS day_of_week,
        CAST(ROUND(sales / quantity_sold) AS DECIMAL (10,2)) AS sales_price_per_unit,
        CAST(ROUND(sales - cost_of_sales) AS DECIMAL (10,2)) AS gross_profit,
        CAST(ROUND((sales - cost_of_sales) / quantity_sold)AS DECIMAL (10,2)) AS gross_profit_per_unit,
        CAST(ROUND(((sales - cost_of_sales) / sales) * 100) AS DECIMAL (10,2)) AS gross_profit_percentage,
        CAST(ROUND(
            (
                ((sales - cost_of_sales) / quantity_sold)
                / (sales / quantity_sold)
            ) * 100
        ) AS DECIMAL (10,2))AS gross_profit_percentage_per_unit

    FROM sales.analytics.sales_cleaned
)

SELECT *
FROM transformed_data;

---final clean table for analysis
SELECT *
FROM sales.analytics.sales_final;

------------------------------------------------------------
---Analysis
-----------------------------------------------------------

--calculating Average Unit Sales Price
SELECT
    ROUND(AVG(sales_price_per_unit), 2) AS average_unit_sales_price
FROM sales.analytics.sales_final; --(37.07)

--calculating monthly sales and quantity sold over the years
SELECT
    year,
    month_number,
    month,
    ROUND(SUM(sales), 2) AS total_sales,
    SUM(quantity_sold) AS total_quantity_sold
FROM sales.analytics.sales_final
GROUP BY year, month_number, month
ORDER BY year, month_number;

--calculating total product sales & profits
SELECT
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(cost_of_sales), 2) AS total_cost_of_sales,
    ROUND(SUM(gross_profit), 2) AS total_gross_profit,
    ROUND((SUM(gross_profit) / SUM(sales)) * 100, 2) AS overall_gross_profit_percentage,
    ROUND(AVG(gross_profit_per_unit), 2) AS avg_gross_profit_per_unit,
    ROUND(AVG(gross_profit_percentage_per_unit), 2) AS avg_gross_profit_percentage_per_unit
FROM sales.analytics.sales_final;

--checking out of the 1053 days of sales, how many were profitable/loss days OR Breakeven
SELECT
    COUNT(*) AS total_days,
    SUM(CASE 
            WHEN gross_profit > 0 THEN 1 ELSE 0 END) AS profitable_days,
    SUM(CASE 
            WHEN gross_profit < 0 THEN 1 ELSE 0 END) AS loss_days,
    SUM(CASE 
            WHEN gross_profit = 0 THEN 1 ELSE 0 END) AS break_even_days
FROM sales.analytics.sales_final;

--checking highest & lowest profit amount
SELECT
    ROUND(MIN(gross_profit), 2) AS largest_loss,
    ROUND(MAX(gross_profit), 2) AS highest_profit
FROM sales.analytics.sales_final;

--checking months with lowest average selling price compared with others in order to try find 3 promotional-period elasticities 
--(NB overall Avg selling price = 37.07)
SELECT
    year,
    month_number,
    month,
    ROUND(AVG(sales_price_per_unit), 2)AS avg_price,
    SUM(quantity_sold) AS total_quantity_sold,
    ROUND(SUM(sales), 2) AS total_sales
FROM sales.analytics.sales_final
GROUP BY
    year,
    month_number,
    month
ORDER BY avg_price ASC; --Top 5 months with lowest avg price= Aug 2014 (32.49), Dec 2013 (32.61), Feb 2014 (32.77), June 2014 (32.95), May 2014 (33.12)

-------------------------------------------------------------------
--investigating Aug 2014 
------------------------------------------------------------------
--checking daily prices
SELECT
    sales_date,
    sales_price_per_unit,
    quantity_sold,
    sales
FROM sales.analytics.sales_final
WHERE sales_date BETWEEN '2014-08-01' AND '2014-08-31'
ORDER BY sales_date;---from 1-25 August prices stay around 32.42 to 33.33 (baseline)
                    --from 26-31 August prices drop sharply from 31.87 to 30.75 (inferred Promotion)

--comparing baseline & inferred promotion periods
SELECT
    CASE
        WHEN sales_date BETWEEN '2014-08-01' AND '2014-08-25'
            THEN 'Baseline'
        WHEN sales_date BETWEEN '2014-08-26' AND '2014-08-31'
            THEN 'Inferred Promotion'
    END AS period,
    ROUND(AVG(sales_price_per_unit), 2) AS avg_price,
    ROUND(AVG(quantity_sold), 2) AS avg_quantity_sold,
    ROUND(SUM(sales), 2) AS total_sales
FROM sales.analytics.sales_final
WHERE sales_date BETWEEN '2014-08-01' AND '2014-08-31'
GROUP BY
    CASE
        WHEN sales_date BETWEEN '2014-08-01' AND '2014-08-25'
            THEN 'Baseline'
        WHEN sales_date BETWEEN '2014-08-26' AND '2014-08-31'
            THEN 'Inferred Promotion'
    END
ORDER BY period; --baseline (avg price = 32.87,avg quantity sold= 9254.84)
                 -- inferred promotion (avg price = 30.95,avg quantity sold= 13200.17)

-- calculating price elasticity (how much quantity is sold changes when the price changes)
--formula: [(Promotion Quantity - Baseline Quantity)/Baseline Quantity]
SELECT
    ROUND(
            (
                (13200.17 - 9254.84) / 9254.84) 
            /(
                (30.95 - 32.87) / 32.87),2
        ) AS price_elasticity; -- (-7.30)

---trying to find if the product performs best (more revenue) or worse when sold at promotional price
SELECT
    CASE
        WHEN sales_date BETWEEN '2014-08-01' AND '2014-08-25'
            THEN 'Baseline (1–25 Aug)'
        WHEN sales_date BETWEEN '2014-08-26' AND '2014-08-31'
            THEN 'Inferred promotion (26–31 Aug)'
    END AS period,
    COUNT(*) AS number_of_days,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(sales) / COUNT(*),2) AS average_daily_sales
FROM sales.analytics.sales_final
WHERE sales_date BETWEEN '2014-08-01' AND '2014-08-31'
GROUP BY
    CASE
        WHEN sales_date BETWEEN '2014-08-01' AND '2014-08-25'
            THEN 'Baseline (1–25 Aug)'
        WHEN sales_date BETWEEN '2014-08-26' AND '2014-08-31'
            THEN 'Inferred promotion (26–31 Aug)'
    END
ORDER BY period; --Baseline avg sales = 302,620.02
                -- Inferred promotion avg sales = 407,479.64 (more revenue)
                --((407,479.64 - 302,620.02)/302,620.02)*100) = 34.65% increase in sales during promotion period

---------------------------------------------------------------------
--investigating Feb 2014 
--------------------------------------------------------------------
--checking daily prices
SELECT
    sales_date,
    sales_price_per_unit,
    quantity_sold,
    sales
FROM sales.analytics.sales_final
WHERE sales_date BETWEEN '2014-02-01' AND '2014-02-28'
ORDER BY sales_date;

--comparing baseline & inferred promotion periods
SELECT 
    CASE 
        WHEN sales_date BETWEEN '2014-02-01' AND '2014-02-20'
            THEN 'Baseline (1–20 Feb)'
        WHEN sales_date BETWEEN '2014-02-21' AND '2014-02-28'
            THEN 'Inferred promotion (21–28 Feb)'
    END AS period,
    ROUND(AVG(sales_price_per_unit), 2) AS average_price,
    ROUND(AVG(quantity_sold), 2) AS average_quantity_sold,
    ROUND(SUM(sales), 2) AS total_sales
FROM sales.analytics.sales_final
WHERE sales_date BETWEEN '2014-02-01' AND '2014-02-28'
GROUP BY 
    CASE 
        WHEN sales_date BETWEEN '2014-02-01' AND '2014-02-20'
            THEN 'Baseline (1–20 Feb)'
        WHEN sales_date BETWEEN '2014-02-21' AND '2014-02-28'
            THEN 'Inferred promotion (21–28 Feb)'
    END
ORDER BY period;    --baseline (avg price = 33.04,avg quantity sold= 5216.35)
                    -- inferred promotion (avg price = 32.09,avg quantity sold= 9213.5)

-- calculating price elasticity (how much quantity is sold changes when the price changes)
--formula: [(Promotion Quantity - Baseline Quantity)/Baseline Quantity]
SELECT
    ROUND(
        (
            (9213.50 - 5216.35) / 5216.35
        ) /
        (
            (32.09 - 33.04) / 33.04
        ),
        2
    ) AS price_elasticity; -- (-26.65)

---trying to find if the product performs best (more revenue) or worse when sold at promotional price
SELECT
    CASE
        WHEN sales_date BETWEEN '2014-02-01' AND '2014-02-20'
            THEN 'Baseline (1–20 Feb)'
        WHEN sales_date BETWEEN '2014-02-21' AND '2014-02-28'
            THEN 'Inferred promotion (21–28 Feb)'
    END AS period,
    COUNT(*) AS number_of_days,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(sales) / COUNT(*),2) AS average_daily_sales
FROM sales.analytics.sales_final
WHERE sales_date BETWEEN '2014-02-01' AND '2014-02-28'
GROUP BY
    CASE
        WHEN sales_date BETWEEN '2014-02-01' AND '2014-02-20'
            THEN 'Baseline (1–20 Feb)'
        WHEN sales_date BETWEEN '2014-02-21' AND '2014-02-28'
            THEN 'Inferred promotion (21–28 Feb)'
    END
ORDER BY period;--Baseline avg sales = 171,274.64
                -- Inferred promotion avg sales = 294,374.30 (more revenue)
                --((294,374.30 -171,274.64 )/171,274.64)*100) = 71.87% increase in sales during promotion period

-------------------------------------------------------------------
--investigating June 2015
------------------------------------------------------------------
--checking daily prices
SELECT
    sales_date,
    sales_price_per_unit,
    quantity_sold,
    sales
FROM sales.analytics.sales_final
WHERE sales_date BETWEEN '2015-06-01' AND '2015-06-30'
ORDER BY sales_date;

----comparing baseline & inferred promotion periods
SELECT 
    CASE 
        WHEN sales_date BETWEEN '2015-06-08' AND '2015-06-23'
            THEN 'Baseline (8–23 Jun)'
        WHEN sales_date BETWEEN '2015-06-24' AND '2015-06-30'
            THEN 'Inferred promotion (24–30 Jun)'
    END AS period,
    ROUND(AVG(sales_price_per_unit), 2) AS average_price,
    ROUND(AVG(quantity_sold), 2) AS average_quantity_sold,
    ROUND(SUM(sales), 2) AS total_sales
FROM sales.analytics.sales_final
WHERE sales_date BETWEEN '2015-06-08' AND '2015-06-30'
GROUP BY 
    CASE 
        WHEN sales_date BETWEEN '2015-06-08' AND '2015-06-23'
            THEN 'Baseline (8–23 Jun)'
        WHEN sales_date BETWEEN '2015-06-24' AND '2015-06-30'
            THEN 'Inferred promotion (24–30 Jun)'
    END
ORDER BY period;--baseline (avg price = 42.03,avg quantity sold= 2558.44)
                 -- inferred promotion (avg price = 37.78,avg quantity sold= 5833.29)

---- calculating price elasticity
SELECT
    ROUND(
        (
            (5833.29 - 2558.44) / 2558.44
        ) /
        (
            (37.78 - 42.03) / 42.03
        ),
        2
    ) AS price_elasticity; -- (-12.66)

---trying to find if the product performs best (more revenue) or worse when sold at promotional price
SELECT
    CASE
        WHEN sales_date BETWEEN '2015-06-08' AND '2015-06-23'
            THEN 'Baseline (8–23 Jun)'
        WHEN sales_date BETWEEN '2015-06-24' AND '2015-06-30'
            THEN 'Inferred promotion (24–30 Jun)'
    END AS period,
    COUNT(*) AS number_of_days,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(sales) / COUNT(*),2) AS average_daily_sales
FROM sales.analytics.sales_final
WHERE sales_date BETWEEN '2015-06-08' AND '2015-06-30'
GROUP BY
    CASE
        WHEN sales_date BETWEEN '2015-06-08' AND '2015-06-23'
            THEN 'Baseline (8–23 Jun)'
        WHEN sales_date BETWEEN '2015-06-24' AND '2015-06-30'
            THEN 'Inferred promotion (24–30 Jun)'
    END
ORDER BY period;--Baseline avg sales = 107,529.37
                -- Inferred promotion avg sales = 220,422.02 (more revenue)
                --((220,422.02 - 107,529.37)/107,529.37)*100) =104.99% increase in sales during promotion period

--comparing gross profit baseline and promotional periods of the 3 identified months
SELECT
    CASE
        WHEN sales_date BETWEEN '2014-08-01' AND '2014-08-25'
            THEN 'August Baseline'
        WHEN sales_date BETWEEN '2014-08-26' AND '2014-08-31'
            THEN 'August Promotion'

        WHEN sales_date BETWEEN '2014-02-01' AND '2014-02-20'
            THEN 'February Baseline'
        WHEN sales_date BETWEEN '2014-02-21' AND '2014-02-28'
            THEN 'February Promotion'

        WHEN sales_date BETWEEN '2015-06-08' AND '2015-06-23'
            THEN 'June Baseline'
        WHEN sales_date BETWEEN '2015-06-24' AND '2015-06-30'
            THEN 'June Promotion'
    END AS period,
    COUNT(*) AS number_of_days,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(cost_of_sales), 2) AS total_cost_of_sales,
    ROUND(SUM(gross_profit), 2) AS total_gross_profit,
    ROUND(SUM(gross_profit) / COUNT(*),2) AS average_daily_gross_profit,
    ROUND((SUM(gross_profit) / SUM(sales)) * 100,2) AS gross_profit_percentage
FROM sales.analytics.sales_final
WHERE
    sales_date BETWEEN '2014-02-01' AND '2014-02-28'
    OR sales_date BETWEEN '2014-08-01' AND '2014-08-31'
    OR sales_date BETWEEN '2015-06-08' AND '2015-06-30'
GROUP BY
    CASE
        WHEN sales_date BETWEEN '2014-08-01' AND '2014-08-25'
            THEN 'August Baseline'
        WHEN sales_date BETWEEN '2014-08-26' AND '2014-08-31'
            THEN 'August Promotion'

        WHEN sales_date BETWEEN '2014-02-01' AND '2014-02-20'
            THEN 'February Baseline'
        WHEN sales_date BETWEEN '2014-02-21' AND '2014-02-28'
            THEN 'February Promotion'

        WHEN sales_date BETWEEN '2015-06-08' AND '2015-06-23'
            THEN 'June Baseline'
        WHEN sales_date BETWEEN '2015-06-24' AND '2015-06-30'
            THEN 'June Promotion'
    END
ORDER BY period; --August 2014 promotion period avg daily profit = -43962.55 & baseline = -10011.15
                 --February 2014 promotion period avg daily profit = -8852.92 & baseline = -3108.40
                 --June 2015 promotion period avg daily profit = -13677.84 & baseline = 4105.10
                 --(At lower prices more quantity was sold and sales were high but gross was low for 2 periods and high in june 2015)

--checking which days produced highest sales and lowset sales (top 10)
SELECT
    sales_date,
    ROUND(sales, 2) AS sales,
    quantity_sold,
    ROUND(sales_price_per_unit, 2) AS sales_price_per_unit
FROM sales.analytics.sales_final
ORDER BY sales DESC
LIMIT 10;