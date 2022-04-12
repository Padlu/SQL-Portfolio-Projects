	/* AIRBNB DATA CLEANING */

	/* CALENDAR TABLES */

--------------------------------------------------------------------------------------------------------------------------------

-- Starting with Calendar data (partition 3). 

SELECT TOP 20 * 
FROM SQL_SSMS_Portfolio_3..Calendar_3

/*

 This Table has in total of 12000000 rows which are a lot to handle (thus divided in 3 files). 
 Most of the rows are duplicates and only dates are unique. 
 Let's clean it to make it useful and small.
 
*/



-- We first remove the unhelpful time part from the date column

SELECT date, CONVERT(date, date)
FROM SQL_SSMS_Portfolio_3..Calendar_3


ALTER TABLE SQL_SSMS_Portfolio_3..Calendar_3
ADD New_Date date

UPDATE SQL_SSMS_Portfolio_3..Calendar_3
SET New_Date = CONVERT(date, date)


SELECT TOP 20 * 	-- Double checking if the new date column is added
FROM SQL_SSMS_Portfolio_3..Calendar_3



-- Now that we added new date column we can drop unused column date

ALTER TABLE SQL_SSMS_Portfolio_3..Calendar_3
DROP COLUMN date

SELECT TOP 20 *		-- Double Checking if the DROP was successful
FROM SQL_SSMS_Portfolio_3..Calendar_3



-- We convert 't' and 'f' in Available field to 'True' and 'False' for better visual interpretation

SELECT DISTINCT available, COUNT(available) AS Count_		-- Checking if we have only 2 distinct values and their count
FROM SQL_SSMS_Portfolio_3..Calendar_3
GROUP BY available



SELECT DISTINCT TOP 200 listing_id, available,		-- To check if the query is right
	CASE WHEN available = 't' THEN 'True'
		WHEN available = 'f' THEN 'False'
		ELSE available
		END
FROM SQL_SSMS_Portfolio_3..Calendar_3

UPDATE SQL_SSMS_Portfolio_3..Calendar_3		-- Making actual update with surety
SET available = CASE WHEN available = 't' THEN 'True'
		WHEN available = 'f' THEN 'False'
		ELSE available
		END

SELECT *		-- Double checking if the data is updated as needed
FROM SQL_SSMS_Portfolio_3..Calendar_3



/* 

 Now the aim is for each unique row we need to select row with starting date and ending date
	and concat a new column with end date besides starting date. 
 This will create a new column with end date and eliminate all the duplicate rows still keeping 
	the same useful information.

*/



-- First, we select unique rows with first date i.e. Starting date


-- Assign rolling ROW_NUMBER count to duplicate rows

SELECT *, ROW_NUMBER() OVER (PARTITION BY listing_id, available, price, adjusted_price, minimum_nights, maximum_nights
	ORDER BY New_Date) as Row_Num
FROM SQL_SSMS_Portfolio_3..Calendar_3		-- All the unique rows are assigned with 1



-- How many unique rows are there without Date?

SELECT DISTINCT listing_id, available, price, adjusted_price, minimum_nights, maximum_nights
FROM SQL_SSMS_Portfolio_3..Calendar_3		-- 4660

/* So we want to make sure we get 4660 rows with Row_Num = 1 */



-- SELECT all with Row_Num = 1 from our Rolling Count Query
-- For this we'll have to use CTE

WITH Temp_Calendar_1 AS (
SELECT *, ROW_NUMBER() OVER (PARTITION BY listing_id, available, price, adjusted_price, minimum_nights, maximum_nights
	ORDER BY New_Date) as Row_Num
FROM SQL_SSMS_Portfolio_3..Calendar_3
)
SELECT *
FROM Temp_Calendar_1
WHERE Row_Num = 1		-- We got the desired result! Great work!



-- Now, we select unique rows with last date i.e. Ending date with same method but by desc count

-- Assign rolling ROW_NUMBER count to duplicate rows in desc order

SELECT *, ROW_NUMBER() OVER (PARTITION BY listing_id, available, price, adjusted_price, minimum_nights, maximum_nights
	ORDER BY New_Date DESC) as Row_Num
FROM SQL_SSMS_Portfolio_3..Calendar_3		-- All the unique rows with ending date are assigned with 1



-- We perform same query as previous to retrieve unique data using CTE but now the difference is we'll have EndDate

WITH Temp_Calendar_2 AS (
SELECT *, ROW_NUMBER() OVER (PARTITION BY listing_id, available, price, adjusted_price, minimum_nights, maximum_nights
	ORDER BY New_Date DESC) as Row_Num
FROM SQL_SSMS_Portfolio_3..Calendar_3
)
SELECT *
FROM Temp_Calendar_2
WHERE Row_Num = 1		-- We got the desired result! Great!



-- Now we JOIN these two CTEs on their unique columns. {COMPLEX QUERY} 
-- //Same can be done in 3 step process by creating 2 temp tables and then performing Join on it.

WITH Temp_Calendar_1 AS (
SELECT *, ROW_NUMBER() OVER (PARTITION BY listing_id, available, price, adjusted_price, minimum_nights, maximum_nights
	ORDER BY New_Date) as Row_Num
FROM SQL_SSMS_Portfolio_3..Calendar_3
), Temp_Calendar_2 AS (
SELECT *, ROW_NUMBER() OVER (PARTITION BY listing_id, available, price, adjusted_price, minimum_nights, maximum_nights
	ORDER BY New_Date DESC) as Row_Num
FROM SQL_SSMS_Portfolio_3..Calendar_3
)
SELECT tc1.listing_id, tc1.available, tc1.price, tc1.adjusted_price, 
	tc1.New_Date AS StartDate, tc2.New_Date AS EndDate, tc1.minimum_nights, tc1.minimum_nights
FROM Temp_Calendar_1 tc1 JOIN Temp_Calendar_2 tc2 
	ON tc1.listing_id = tc2.listing_id 
		AND tc1.available = tc2.available
		AND tc1.price = tc2.price
		AND tc1.adjusted_price = tc2.adjusted_price
		AND tc1.minimum_nights = tc2.minimum_nights
		AND tc1.maximum_nights = tc2.maximum_nights
WHERE tc1.Row_Num = 1
	AND tc2.Row_Num = 1		-- Congratulations! We got the perfect final optimized cleaned data output!


-- Amazingly Well Done!



-- Now, we save this Cleaned Data in a view for future reference

CREATE VIEW Cleaned_Calendar_3 
AS
WITH Temp_Calendar_1 AS (
SELECT *, ROW_NUMBER() OVER (PARTITION BY listing_id, available, price, adjusted_price, minimum_nights, maximum_nights
	ORDER BY New_Date) as Row_Num
FROM SQL_SSMS_Portfolio_3..Calendar_3
), Temp_Calendar_2 AS (
SELECT *, ROW_NUMBER() OVER (PARTITION BY listing_id, available, price, adjusted_price, minimum_nights, maximum_nights
	ORDER BY New_Date DESC) as Row_Num
FROM SQL_SSMS_Portfolio_3..Calendar_3
)
SELECT tc1.listing_id, tc1.available, tc1.price, tc1.adjusted_price, 
	tc1.New_Date AS StartDate, tc2.New_Date AS EndDate, tc1.minimum_nights, tc1.maximum_nights
FROM Temp_Calendar_1 tc1 JOIN Temp_Calendar_2 tc2 
	ON tc1.listing_id = tc2.listing_id 
		AND tc1.available = tc2.available
		AND tc1.price = tc2.price
		AND tc1.adjusted_price = tc2.adjusted_price
		AND tc1.minimum_nights = tc2.minimum_nights
		AND tc1.maximum_nights = tc2.maximum_nights
WHERE tc1.Row_Num = 1
	AND tc2.Row_Num = 1



-- Querying the data from our newly created View Cleaned_Calendar_3

SELECT *
FROM Cleaned_Calendar_3

-- Perfectly Done!

--------------------------------------------------------------------------------------------------------------------------------

/*

 We now perform the same cleaning steps for the rest two partitions of the Calendar table

*/


-- For Calendar Table 1 --



-- Removing the unhelpful time part from the date column

ALTER TABLE SQL_SSMS_Portfolio_3..Calendar_1
ADD New_Date date

UPDATE SQL_SSMS_Portfolio_3..Calendar_1
SET New_Date = CONVERT(date, date)

SELECT TOP 20 * 	-- Double checking if the new date column is added
FROM SQL_SSMS_Portfolio_3..Calendar_1

ALTER TABLE SQL_SSMS_Portfolio_3..Calendar_1		-- Drop unused column date
DROP COLUMN date

SELECT TOP 20 *		-- Double Checking if the DROP was successful
FROM SQL_SSMS_Portfolio_3..Calendar_1



-- Converting 't' and 'f' in Available field to 'True' and 'False' for better visual interpretation

UPDATE SQL_SSMS_Portfolio_3..Calendar_1		-- Making actual update with surety
SET available = CASE WHEN available = 't' THEN 'True'
		WHEN available = 'f' THEN 'False'
		ELSE available
		END

SELECT *		-- Double checking if the data is updated as needed
FROM SQL_SSMS_Portfolio_3..Calendar_1



-- How many unique rows are there without Date?

SELECT DISTINCT listing_id, available, price, adjusted_price, minimum_nights, maximum_nights
FROM SQL_SSMS_Portfolio_3..Calendar_1		-- 5532



-- We Select the unique Data w/ Start and End Date using CTE and their JOIN as previous table
-- We Expect to see 5532 unique rows.

WITH Temp_Calendar_1 AS (
SELECT *, ROW_NUMBER() OVER (PARTITION BY listing_id, available, price, adjusted_price, minimum_nights, maximum_nights
	ORDER BY New_Date) as Row_Num
FROM SQL_SSMS_Portfolio_3..Calendar_1
), Temp_Calendar_2 AS (
SELECT *, ROW_NUMBER() OVER (PARTITION BY listing_id, available, price, adjusted_price, minimum_nights, maximum_nights
	ORDER BY New_Date DESC) as Row_Num
FROM SQL_SSMS_Portfolio_3..Calendar_1
)
SELECT tc1.listing_id, tc1.available, tc1.price, tc1.adjusted_price, 
	tc1.New_Date AS StartDate, tc2.New_Date AS EndDate, tc1.minimum_nights, tc1.maximum_nights
FROM Temp_Calendar_1 tc1 JOIN Temp_Calendar_2 tc2 
	ON tc1.listing_id = tc2.listing_id 
		AND tc1.available = tc2.available
		AND tc1.price = tc2.price
		AND tc1.adjusted_price = tc2.adjusted_price
		AND tc1.minimum_nights = tc2.minimum_nights
		AND tc1.maximum_nights = tc2.maximum_nights
WHERE tc1.Row_Num = 1
	AND tc2.Row_Num = 1		-- We retrieved the required Data but 2 unique rows were missing.

	-- We proceed forward with the retrieved data as it looks correct.

/*

	After investigating the 2 missing rows, it was found that 2 missing rows were the ones which had NULL values in
	price and adjusted price field.

	And, so the join we created removed those unrequired entries as price is necessary attribute for a listing.

*/


-- Creating View of this Cleaned Data for future reference

CREATE VIEW Cleaned_Calendar_1
AS
WITH Temp_Calendar_1 AS (
SELECT *, ROW_NUMBER() OVER (PARTITION BY listing_id, available, price, adjusted_price, minimum_nights, maximum_nights
	ORDER BY New_Date) as Row_Num
FROM SQL_SSMS_Portfolio_3..Calendar_1
), Temp_Calendar_2 AS (
SELECT *, ROW_NUMBER() OVER (PARTITION BY listing_id, available, price, adjusted_price, minimum_nights, maximum_nights
	ORDER BY New_Date DESC) as Row_Num
FROM SQL_SSMS_Portfolio_3..Calendar_1
)
SELECT tc1.listing_id, tc1.available, tc1.price, tc1.adjusted_price, 
	tc1.New_Date AS StartDate, tc2.New_Date AS EndDate, tc1.minimum_nights, tc1.maximum_nights
FROM Temp_Calendar_1 tc1 JOIN Temp_Calendar_2 tc2 
	ON tc1.listing_id = tc2.listing_id 
		AND tc1.available = tc2.available
		AND tc1.price = tc2.price
		AND tc1.adjusted_price = tc2.adjusted_price
		AND tc1.minimum_nights = tc2.minimum_nights
		AND tc1.maximum_nights = tc2.maximum_nights
WHERE tc1.Row_Num = 1
	AND tc2.Row_Num = 1


SELECT * -- Querying the data from our newly created View Cleaned_Calendar_1
FROM Cleaned_Calendar_1


/*

-- Investigating the missing 2 rows.

SELECT *
FROM SQL_SSMS_Portfolio_3..Calendar_1
WHERE price IS NULL


SELECT c1.listing_id, c1.available, c1.price, c1.adjusted_price, 
	cc1.StartDate, cc1.EndDate, c1.minimum_nights, c1.maximum_nights
FROM SQL_SSMS_Portfolio_3..Calendar_1 c1
	LEFT JOIN Cleaned_Calendar_1 cc1
	ON c1.listing_id = cc1.listing_id 
		AND c1.available = cc1.available
		AND c1.price = cc1.price
		AND c1.adjusted_price = cc1.adjusted_price
		AND c1.minimum_nights = cc1.minimum_nights
		AND c1.maximum_nights = cc1.maximum_nights
WHERE cc1.StartDate IS NULL

*/

-- For Calendar Table 2 --



-- Removing the unhelpful time part from the date column

ALTER TABLE SQL_SSMS_Portfolio_3..Calendar_2
ADD New_Date date

UPDATE SQL_SSMS_Portfolio_3..Calendar_2
SET New_Date = CONVERT(date, date)

SELECT TOP 20 * 	-- Double checking if the new date column is added
FROM SQL_SSMS_Portfolio_3..Calendar_2

ALTER TABLE SQL_SSMS_Portfolio_3..Calendar_2		-- Drop unused column date
DROP COLUMN date

SELECT TOP 20 *		-- Double Checking if the DROP was successful
FROM SQL_SSMS_Portfolio_3..Calendar_2



-- Converting 't' and 'f' in Available field to 'True' and 'False' for better visual interpretation

UPDATE SQL_SSMS_Portfolio_3..Calendar_2		-- Making actual update with surety
SET available = CASE WHEN available = 't' THEN 'True'
		WHEN available = 'f' THEN 'False'
		ELSE available
		END

SELECT *		-- Double checking if the data is updated as needed
FROM SQL_SSMS_Portfolio_3..Calendar_2



-- How many unique rows are there without Date?

SELECT DISTINCT listing_id, available, price, adjusted_price, minimum_nights, maximum_nights
FROM SQL_SSMS_Portfolio_3..Calendar_2		-- 6385



-- We Select the unique Data w/ Start and End Date using CTE and their JOIN as previous table
-- We Expect to see 6385 unique rows or lower considering removal of NULL entries.

WITH Temp_Calendar_1 AS (
SELECT *, ROW_NUMBER() OVER (PARTITION BY listing_id, available, price, adjusted_price, minimum_nights, maximum_nights
	ORDER BY New_Date) as Row_Num
FROM SQL_SSMS_Portfolio_3..Calendar_2
), Temp_Calendar_2 AS (
SELECT *, ROW_NUMBER() OVER (PARTITION BY listing_id, available, price, adjusted_price, minimum_nights, maximum_nights
	ORDER BY New_Date DESC) as Row_Num
FROM SQL_SSMS_Portfolio_3..Calendar_2
)
SELECT tc1.listing_id, tc1.available, tc1.price, tc1.adjusted_price, 
	tc1.New_Date AS StartDate, tc2.New_Date AS EndDate, tc1.minimum_nights, tc1.maximum_nights
FROM Temp_Calendar_1 tc1 JOIN Temp_Calendar_2 tc2 
	ON tc1.listing_id = tc2.listing_id 
		AND tc1.available = tc2.available
		AND tc1.price = tc2.price
		AND tc1.adjusted_price = tc2.adjusted_price
		AND tc1.minimum_nights = tc2.minimum_nights
		AND tc1.maximum_nights = tc2.maximum_nights
WHERE tc1.Row_Num = 1
	AND tc2.Row_Num = 1		-- We retrieved the required unique Data. Job Well Done!



-- Creating View of this Cleaned Data for future reference

CREATE VIEW Cleaned_Calendar_2
AS
WITH Temp_Calendar_1 AS (
SELECT *, ROW_NUMBER() OVER (PARTITION BY listing_id, available, price, adjusted_price, minimum_nights, maximum_nights
	ORDER BY New_Date) as Row_Num
FROM SQL_SSMS_Portfolio_3..Calendar_2
), Temp_Calendar_2 AS (
SELECT *, ROW_NUMBER() OVER (PARTITION BY listing_id, available, price, adjusted_price, minimum_nights, maximum_nights
	ORDER BY New_Date DESC) as Row_Num
FROM SQL_SSMS_Portfolio_3..Calendar_2
)
SELECT tc1.listing_id, tc1.available, tc1.price, tc1.adjusted_price, 
	tc1.New_Date AS StartDate, tc2.New_Date AS EndDate, tc1.minimum_nights, tc1.maximum_nights
FROM Temp_Calendar_1 tc1 JOIN Temp_Calendar_2 tc2 
	ON tc1.listing_id = tc2.listing_id 
		AND tc1.available = tc2.available
		AND tc1.price = tc2.price
		AND tc1.adjusted_price = tc2.adjusted_price
		AND tc1.minimum_nights = tc2.minimum_nights
		AND tc1.maximum_nights = tc2.maximum_nights
WHERE tc1.Row_Num = 1
	AND tc2.Row_Num = 1


SELECT * -- Querying the data from our newly created View Cleaned_Calendar_2
FROM Cleaned_Calendar_2


--------------------------------------------------------------------------------------------------------------------------------

/* Now we Combine the 3 Cleaned parts of Calendar table to get a single Cleaned Calendar Table */



-- Using UNION ALL we combine the three cleaned Calendar tables

SELECT 'C1' AS Table_, *		-- Create a New Column to have a track which rows are from which table for future reference
FROM Cleaned_Calendar_1
UNION ALL
SELECT 'C2', *
FROM Cleaned_Calendar_2
UNION ALL
SELECT 'C3', *
FROM Cleaned_Calendar_3



-- Save this table as a View for future use

CREATE VIEW Cleaned_Calendar
AS
SELECT 'C1' AS Table_, *
FROM Cleaned_Calendar_1
UNION ALL
SELECT 'C2', *
FROM Cleaned_Calendar_2
UNION ALL
SELECT 'C3', *
FROM Cleaned_Calendar_3



SELECT *		-- Querying the from newly created View Cleaned_Calendar
FROM Cleaned_Calendar



/* We make sure that this newly created data is good to use by checking it further */



-- Checking for duplicates

SELECT DISTINCT listing_id, available, price, adjusted_price, StartDate, EndDate, minimum_nights, maximum_nights 
FROM Cleaned_Calendar		-- No Duplicates Present.



-- Checking for NULL entries

SELECT *
FROM Cleaned_Calendar
WHERE listing_id IS NULL
	OR available IS NULL
	OR price IS NULL
	OR adjusted_price IS NULL
	OR StartDate IS NULL
	OR EndDate IS NULL
	OR minimum_nights IS NULL
	OR maximum_nights IS NULL		-- NO NULL Values Present



-- Checking if the Start Date is always less than End Date

SELECT *
FROM Cleaned_Calendar
WHERE StartDate > EndDate		-- No incorrect entries!



-- This Data Table is Fully Cleaned and Good to go for future Data analysis!

--------------------------------------------------------------------------------------------------------------------------------
