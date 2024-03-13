
/*
Author: Mihret Gashahun Gebreyes 
Date: 12.3.2024
Description: SQL script for analyzing Ethiopian food prices, including comparisons of item prices by region, price percentage increase by year, comparison of regional average prices with total average price, coffee price distribution in different regions, and comparison of official and unofficial exchange rates.
*/


-- This SQL script compares item prices by region using the Wholesale price type and excluding non-food items. It calculates the average prices in Ethiopian Birr (ETB) and US dollars (USD) for each item in different regions.

WITH CTE1 AS (
    SELECT 
        adm1_name,
        item_name,
        AVG(value) AS Average_price_ETB,
        AVG(value_usd) AS Average_price_USD,
        item_unit
    FROM 
        [dbo].[food_prices_eth] food
    WHERE 
        food.item_price_type ='Wholesale' AND  item_type != 'non-food'
    GROUP BY 
        adm1_name, item_name, item_unit
)
SELECT 
    adm1_name,
    item_name,
    Average_price_ETB,
    Average_price_USD,
    item_unit,
    RANK () OVER (PARTITION BY item_name ORDER BY Average_price_ETB) price_ranking
FROM 
    CTE1;

	-- This SQL script calculates the percentage increase in prices for each item by comparing the average prices of consecutive years.

SELECT 
    item_name,
    YEAR([Date]) AS logged_year,
    AVG(value) AS avg_price_ETB,
    (LAG(AVG([value])) OVER (PARTITION BY item_name ORDER BY item_name, YEAR([Date]))) AS previous_price,
    (LEAD(AVG([value])) OVER (PARTITION BY item_name ORDER BY item_name, YEAR([Date]))) AS next_price,
    ((AVG(value) - LAG(AVG([value])) OVER (PARTITION BY item_name ORDER BY item_name, YEAR([Date])))) / AVG(value) * 100 AS percent_next_current
FROM 
    [dbo].[food_prices_eth]
WHERE  
    item_type != 'non-food'
GROUP BY 
    item_name, YEAR([Date]);
-- This SQL script compares regional average prices with the total average price of items and categorizes them as above average, below average, or average.

WITH CTE1 AS  ( 
    SELECT 
        item_name,
        item_type,
        YEAR(date) AS date_logged,
        AVG(value) AS total_avg_price 
    FROM 
        [dbo].[food_prices_eth]
    GROUP BY 
        item_name, item_type, YEAR(date)
),
CTE2 AS (
    SELECT 
        adm1_name,
        item_type,
        YEAR(date) AS date_logged,
        item_name,
        AVG(value) AS regional_avg_price
    FROM 
        [dbo].[food_prices_eth]
    GROUP BY 
        adm1_name, item_name, item_type, YEAR(date)
)
SELECT 
    adm1_name,
    CTE2.item_name,
    CTE2.date_logged,
    regional_avg_price,
    total_avg_price,
    CASE 
        WHEN regional_avg_price > total_avg_price THEN 'ABOVE AVERAGE'
        WHEN regional_avg_price < total_avg_price THEN 'BELOW AVERAGE'
        ELSE 'AVERAGE'
    END AS label 
FROM 
    CTE1
JOIN 
    CTE2 ON CTE1.item_name = cte2.item_name AND CTE1.date_logged = CTE2.date_logged
WHERE  
    CTE1.item_type != 'non-food'
ORDER BY 
    1, 2, 3 DESC;
-- This SQL script creates temporary tables to analyze the price distribution of coffee in different regions and years.

CREATE TABLE #MyTempTable (
    year_logged INT,
    avg_price INT
);

-- Insert selected data
INSERT INTO #MyTempTable
SELECT 
    YEAR(date) AS year_logged,
    AVG(VALUE) AS avg_price 
FROM 
    [dbo].[food_prices_eth]
WHERE 
    item_name = 'coffee'
GROUP BY 
    YEAR(date);

CREATE TABLE #MyTempTable2 (
    adm1_name VARCHAR(50),
    year_logged INT,
    avg_value FLOAT,
    min_price_ETB FLOAT,
    max_price_ETB FLOAT,
    stand_deviation FLOAT
);

INSERT INTO #MyTempTable2
SELECT 
    adm1_name,
    YEAR(date) AS year_logged,
    AVG(value) AS avg_value,
    MIN(value) AS min_price_ETB,
    MAX(value) AS max_price_ETB,
    STDEV(value) AS stand_deviation 
FROM 
    [dbo].[food_prices_eth]
WHERE 
    item_name = 'coffee'
GROUP BY 
    adm1_name, YEAR(date)
ORDER BY 
    adm1_name, YEAR(date);

-- Compare regional and yearly prices
SELECT 
    adm1_name,
    t1.year_logged,
    avg_value AS Average_RP,
    avg_price AS Average_YP,
    min_price_ETB,
    max_price_ETB,
    stand_deviation,
    (avg_value - avg_price) / avg_value * 100 AS percent_regional_yearly
FROM 
    #MyTempTable2 t2
JOIN 
    #MyTempTable t1 ON t2.year_logged = t1.year_logged;
-- This SQL script compares official and unofficial exchange rates over different years.

SELECT 
    YEAR(date) AS year_loogged,
    AVG(value) AS RateUnofficial,
    AVG(value / value_usd) AS RateOfficial, 
	(AVG(value)- AVG(value / value_usd))/AVG(value)*100 Percent_diffrence
FROM 
    [dbo].[food_prices_eth]
WHERE  
    item_type = 'non-food' AND item_name = 'Exchange rate (unofficial)'
GROUP BY 
    YEAR(date)
ORDER BY 
    YEAR(date);
