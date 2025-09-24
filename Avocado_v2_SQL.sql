SELECT * 
FROM avocado_v2
;
-- Welcome to Avocado Price Analytics! My goal here is to clean and analyze Avocado Sales data from 2015-2018 by region and by either conventional or organic. 
-- Lets begin by cleaning the data 
-- We have an odd column, lets delete that since it doesnt have anything to do with our process.
ALTER TABLE avocado_v2
DROP COLUMN MyUnknownColumn;

-- Next lets check for missing values, misspellings and duplicates. 
-- Lets start by checking for any misspelling in region
SELECT DISTINCT Region
FROM avocado_v2
;
-- It appears we have pre-aggregated values as larger regions. I know from prior analysis of this dataset these are in fact overlaps. Lets remove them 

DELETE FROM  avocado_v2
WHERE Region IN (
	'Midsouth',
    'Northeast',
    'Plains',
    'SouthCentral',
    'Southeast',
    'TotalUS',
    'West'
    )
;

-- Next lets check for null values

Select 
        SUM(CASE WHEN Date IS NULL OR Date = 0 THEN 1 ELSE 0 END) AS Date,
        SUM(CASE WHEN AveragePrice IS NULL OR AveragePrice = 0 THEN 1 ELSE 0 END) AS AveragePrice,
        SUM(CASE WHEN `Total Volume` IS NULL OR `Total Volume` = 0 THEN 1 ELSE 0 END) As 'Total Volume',
        SUM(CASE WHEN Type IS NULL OR Type = '' THEN 1 ELSE 0 END) AS Type,
        SUM(CASE WHEN Year IS NULL OR Year = 0 THEN 1 ELSE 0 END) AS Year,
        SUM(CASE WHEN Region IS NULL OR Region = '' THEN 1 ELSE 0 END) AS Region
	FROM avocado_v2
    ;
-- No null values, lets check duplicates 

SELECT Date, Region, Type, COUNT(*)
  FROM avocado_v2
  GROUP BY Date, Region, Type
  HAVING COUNT(*) > 1;
  
-- No duplicates either, perfect!

-- Finally lets check the date, first lets see how the date is set, as date or VARCHAR 

DESCRIBE avocado_v2
;

-- Its text, that will make it easier to clean and validate. 

 SELECT DISTINCT Date
 FROM avocado_v2
 WHERE STR_TO_DATE(Date, '%Y-%m-%d') IS NULL
 ;
-- Dates are good, lets check pricing now for any outliers. 

  SELECT MIN(AveragePrice), MAX(AveragePrice) 
  FROM avocado_v2
  ;
  
-- Minimum and Maximum price seem reasonable. 

-- Lets check year lastly. 

SELECT DISTINCT year
FROM avocado_v2
;
-- All correct! 
-- Alight, lets start some exploratory analysis. 
-- Lets brekadown the sales by region and type (conventional and organic)

SELECT *
FROM avocado_v2
WHERE Type = 'conventional' 
;

-- This is pretty messy, and it seems like the data is recorded once a week. Lets try to group this together by quarter for ease of analysis

SELECT 
	YEAR(Date) AS Year,
    QUARTER(DATE) AS quarter,
    Region,
    AVG(AveragePrice) AS Avg_Price,
    SUM(TotalVolume) AS Total_Volume
FROM avocado_v2
GROUP BY year, quarter, region 
ORDER BY year, quarter, region 
;

-- I get an error, the total volume column is throwing an error due to a space in the name. Lets change this real quick. 

START TRANSACTION;

-- I like transactions as a "SandBox" mode to test things out.

ALTER TABLE avocado_v2
CHANGE COLUMN `total volume` Total_Volume DECIMAL (12,2)
;

SELECT *
FROM avocado_v2
WHERE Type = 'conventional' 
;

-- Perfect, lets commit this. 

COMMIT;

-- Now lets add a permanent column for Quarter
START TRANSACTION; 

ALTER TABLE avocado_v2
ADD COLUMN Quarter TINYINT;

SELECT *
FROM avocado_v2
;

UPDATE avocado_v2
SET quarter = QUARTER(Date);

COMMIT;

-- We now have a column for quarter, lets combine that with year. 

START TRANSACTION; 

ALTER TABLE avocado_v2
ADD COLUMN year_quarter VARCHAR(10);

SELECT *
FROM avocado_v2
;

UPDATE avocado_v2
SET year_quarter = CONCAT ('Q', quarter, '-', year);

COMMIT;

-- Perfect, this now added in a better aggregation for dates. 




SELECT 
	Type,
    year_quarter,
    Region,
    ROUND(AVG(AveragePrice),2) AS Avg_Price,
    ROUND(SUM(Total_Volume),2) AS Total_Volume
FROM avocado_v2
WHERE Type = 'Conventional'
GROUP BY year_quarter, region, type
ORDER BY year_quarter, region, type
;

-- Perfect, we now have a much cleaner output. We have each quarter with the respective year, the avgerage price by quarter, and the total volme by quarter. 
-- Lets do the same for organic

SELECT 
	Type,
	year_quarter,
    Region,
    ROUND(AVG(AveragePrice),2) AS Avg_Price,
    ROUND(SUM(Total_Volume),2) AS Total_Volume
FROM avocado_v2
WHERE Type = 'Organic'
GROUP BY year_quarter, region, type
ORDER BY year_quarter, region, type
;

-- Perfect! 

-- Finally, lets see the totals for individual volume and total bag volume. 

SELECT 
	Type,
	year_quarter,
    Region,
    ROUND(SUM(`4046`) + SUM(`4225`) + SUM(`4770`),2) AS Total_Individual_Volume,
    ROUND(SUM(`Small Bags`) + SUM(`Large Bags`) + SUM(`XLarge Bags`),2) AS Total_Bag_Volume
FROM avocado_v2
WHERE Type = 'Conventional'
GROUP BY year_quarter, region, type
ORDER BY year_quarter, region, type
;

-- Great, we have it for conventional, lets do organic 

SELECT 
	Type,
	year_quarter,
    Region,
    ROUND(SUM(`4046`) + SUM(`4225`) + SUM(`4770`),2) AS Total_Individual_Volume,
    ROUND(SUM(`Small Bags`) + SUM(`Large Bags`) + SUM(`XLarge Bags`),2) AS Total_Bag_Volume
FROM avocado_v2
WHERE Type = 'Organic'
GROUP BY year_quarter, region, type
ORDER BY year_quarter, region, type
;

-- We now have 4 great outputs that will make great visualizationss. 

SELECT 
    CONCAT('Q', `quarter`, '-', `year`) AS year_quarter,
    Region,
    Type,
    AVG(AveragePrice) AS avg_price,
    SUM(Total_Volume) AS total_volume
FROM avocado_v2
GROUP BY year_quarter, Region, Type
ORDER BY year_quarter, Region, Type;

START TRANSACTION; 

ALTER TABLE avocado_v2
ADD COLUMN Quarter TINYINT;

SELECT *
FROM avocado_v2
;

UPDATE avocado_v2
SET quarter = QUARTER(Date);

COMMIT;
