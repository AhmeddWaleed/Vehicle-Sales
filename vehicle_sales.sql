SELECT * FROM car_sales.car_sales_data;

-- creating a copy of the dataset

CREATE TABLE car_sales_copy
LIKE car_sales_data ;

INSERT car_sales_copy
SELECT * 
FROM car_sales_data ;

SELECT * 
FROM car_sales_copy ;


-- checking if there are any duplicates

SELECT `year`, make , model , trim , body , transmission , vin , state , `condition` , odometer ,
color, interior, seller , mmr , sellingprice , saledate , new_saledatetime , new_sale_date , new_sale_time ,
  COUNT(*) as total_sold_cars
 FROM car_sales_copy
GROUP BY `year`, make , model , trim , body , transmission , vin , state , `condition` , odometer ,
color, interior, seller , mmr , sellingprice , saledate , new_saledatetime , new_sale_date , new_sale_time 
HAVING COUNT(*) > 1;


-- checking if there are any nulls

SELECT * 
FROM car_sales_copy
where `year` IS NULL 
     or make IS NULL 
     or model IS NULL 
     or trim IS NULL 
     or body IS NULL 
     or transmission IS NULL 
     or vin IS NULL 
     or state  IS NULL 
     or `condition` IS NULL 
     or odometer IS NULL 
     or color IS NULL 
     or interior IS NULL 
     or seller IS NULL 
     or mmr IS NULL 
     or sellingprice IS NULL 
     or saledate IS NULL 
     or new_saledatetime IS NULL 
     or new_sale_date IS NULL 
     or new_sale_time IS NULL ;


-- checking if there are any blanks

-- a- deleting rows where critical fields are blank

SELECT *                   -- in this : the make , model and trim were missing
FROM car_sales_copy
where  make = '' ;     

DELETE 
FROM car_sales_copy
WHERE make = '';     


-- b- filling blanks in model column based on another similar rows 

SELECT * 
FROM car_sales_copy
where  model = '' ;

UPDATE car_sales_copy
SET model = '7 Series'
WHERE  model = '' and make= 'BMW' and trim = '750Li' or
 trim = '750i' or trim = '750i xDrive' or trim = '750Li xDrive';
 
 UPDATE car_sales_copy
SET model = '6 Series'
WHERE  model = '' and make= 'BMW' and trim = '650i xDrive';

UPDATE car_sales_copy
SET model = 'Unknown'
WHERE  model = '' and make= 'Audi' and trim = '2.0 TFSI Premium quattro' ;


-- c- Replace blanks with “Unknown” (non-critical fields):

UPDATE car_sales_copy
SET trim = 'Unknown'
WHERE trim = '';

UPDATE car_sales_copy
SET body = 'Unknown'
WHERE body = '';

UPDATE car_sales_copy
SET transmission = 'Unknown'
WHERE transmission = '';

UPDATE car_sales_copy
SET color = 'Unknown'
WHERE color = '';

UPDATE car_sales_copy
SET interior = 'Unknown'
WHERE interior = '';


-- changing the format of date from string to date , splitting the new date column into date column &
-- hours column and add the new columns

ALTER TABLE car_sales_copy
ADD COLUMN new_saledatetime DATETIME,
ADD COLUMN new_sale_date DATE,
ADD COLUMN new_sale_time TIME;


UPDATE car_sales_copy
SET    
  new_saledatetime = STR_TO_DATE(LEFT(saledate, 24), '%a %b %d %Y %H:%i:%s'),
  new_sale_date = DATE(STR_TO_DATE(LEFT(saledate, 24), '%a %b %d %Y %H:%i:%s')),
  new_sale_time = TIME(STR_TO_DATE(LEFT(saledate, 24), '%a %b %d %Y %H:%i:%s'));
  
-- deleting the old column of date
  
  ALTER TABLE car_sales_copy
  DROP COLUMN saledate;
  
  
  -- Standardizing  the make name
  
SELECT 
DISTINCT make
FROM car_sales_copy; 

UPDATE car_sales_copy
SET make = 'Mercedes-Benz'
WHERE make = 'mercedes-b' or make = 'mercedes' ;

UPDATE car_sales_copy
SET make = 'Land Rover'
WHERE make = 'landrover';

UPDATE car_sales_copy
SET make = 'Volkswagen'
WHERE make = 'vw';


-- changing sellingprice  data type from int to float

ALTER TABLE car_sales_copy
MODIFY sellingprice FLOAT;
  
  
  -- [1] total number of rows

SELECT count(*) 
FROM car_sales_copy;


-- [2] TOP 10 SELLING CARS by make (volume , total sales )

SELECT 
    make ,
    COUNT(*) AS total_sold_cars ,
    SUM(sellingprice) AS total_sales
FROM car_sales_copy
group by make 
order by total_sales DESC
LIMIT 10 ; 


-- [3] Total sales and count of cars sold by make and model
 
SELECT 
    make ,
    model,
    COUNT(*) AS total_sold_cars,
    SUM(sellingprice) AS total_sales
FROM car_sales_copy
group by make , model
order by total_sales DESC ; 


-- [4] Top 20 highest average priced cars by make & models

SELECT 
    make, 
    model,
    ROUND(AVG(sellingprice), 2) AS avg_price
FROM car_sales_copy
GROUP BY make, model
HAVING COUNT(*) > 50    -- ensures no rare outliers dominate
ORDER BY avg_price DESC
LIMIT 20;


-- [5] Monthly Sales Trend (volume , total sales)

SELECT 
	DATE_FORMAT(new_sale_date, '%Y-%m') AS month,
	COUNT(*) AS total_sold_cars,
	SUM(sellingprice) AS total_sales
FROM car_sales_copy
GROUP BY  month
ORDER BY month;


-- [6] Peak Sale Hours

SELECT
	HOUR(new_sale_time) AS hour,
	COUNT(*) AS total_sold_cars
FROM car_sales_copy
GROUP BY hour
ORDER BY total_sold_cars DESC;


-- [7] Average Price and count of sold cars by Condition category

SELECT 
   `condition`,
	condition_state ,
	ROUND(AVG(sellingprice), 2) AS avg_price,
	COUNT(*) AS total_sold_cars
FROM car_sales_copy
GROUP BY `condition` ,condition_state
ORDER BY avg_price DESC;


-- [8] Top 10 sellers by sales volume & total sales

SELECT 
	seller,
	COUNT(*) AS total_sold_cars,
	SUM(sellingprice) AS total_sales
FROM car_sales_copy
GROUP BY seller
ORDER BY total_sold_cars DESC
LIMIT 10;


-- [9] Mileage Impact on Price

SELECT 
  CASE 
    WHEN odometer < 25000 THEN 'Low'
    WHEN odometer BETWEEN 25000 AND 75000 THEN 'Medium'
    ELSE 'High'
  END AS mileage_category,
  ROUND(AVG(sellingprice), 2) AS avg_price,
  COUNT(*) AS total_sold_cars
FROM car_sales_copy
GROUP BY mileage_category;


-- [10] Most Profitable Car Models (High Avg Price & Sales Volume)

SELECT
    model,
    COUNT(*) AS total_sold_cars,
    ROUND(AVG(sellingprice), 2) AS avg_price
FROM car_sales_copy
GROUP BY model
HAVING 
    COUNT(*) > 500 
    AND AVG(sellingprice) > (SELECT AVG(sellingprice) FROM car_sales_copy)
ORDER BY avg_price DESC;


-- [11] sales by make and year (volume , total sales , avg sales) 

SELECT 
    YEAR(new_sale_date) AS sale_year,
    make,
    COUNT(*) AS total_sold_cars,
    SUM(sellingprice) AS total_sales,
    ROUND(AVG(sellingprice), 2) AS avg_price
FROM car_sales_copy
GROUP BY make, sale_year
ORDER BY sale_year, total_sales DESC;


-- [12] sales by make , model & year (volume , total sales)

SELECT 
    YEAR(new_sale_date) AS sale_year,
    make,
    model,
    COUNT(*) AS total_sold_cars,
    SUM(sellingprice) AS total_sales
FROM car_sales_copy
GROUP BY make, model, sale_year
ORDER BY sale_year, total_sales DESC;

-- [13] Sales by seller & state (volume , total sales)

SELECT
    state,
    seller,
    COUNT(*) AS total_sold_cars,
    SUM(sellingprice) AS total_sales
FROM car_sales_copy
GROUP BY state, seller
ORDER BY total_sales DESC;


-- [14] classification according to the condition of cars and adding it to the table

ALTER TABLE car_sales_copy
ADD column condition_state varchar(100) ;

update car_sales_copy
set condition_state = (
CASE
    WHEN `condition` < 10 THEN 'bad condition'
    WHEN `condition` between 10 and 30 THEN 'average condition'
    WHEN `condition` between 30 and 40 THEN 'good condition'
    ELSE 'excellent condition'
   END
);
















