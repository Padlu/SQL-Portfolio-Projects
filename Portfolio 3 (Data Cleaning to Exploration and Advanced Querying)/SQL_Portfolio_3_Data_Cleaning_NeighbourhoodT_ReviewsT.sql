	/* AIRBNB DATA CLEANING */

	/* NEIGHBOURHOOD & REVIEWS TABLE */

--------------------------------------------------------------------------------------------------------------------------------

	/* NEIGHBOURHOOD TABLE */

SELECT *
FROM SQL_SSMS_Portfolio_3..Neighbourhoods



-- Removing NULL Column Neighbourhood_group

ALTER TABLE Neighbourhoods
DROP COLUMN neighbourhood_group



-- This Data Table is Fully Cleaned and Good to go for future Data analysis!

--------------------------------------------------------------------------------------------------------------------------------

	/* REVIEWS TABLE */

SELECT *
FROM SQL_SSMS_Portfolio_3..Reviews



-- Removing unnecessary time part from the Date field

ALTER TABLE Reviews
ADD NewDate DATE

UPDATE SQL_SSMS_Portfolio_3..Reviews
SET NewDate = CONVERT(DATE, date)

ALTER TABLE Reviews
DROP COLUMN date

SELECT *
FROM SQL_SSMS_Portfolio_3..Reviews		-- 81,182 Rows



-- Checking for duplicates

SELECT DISTINCT *
FROM SQL_SSMS_Portfolio_3..Reviews		-- No Duplicates Found! (81,182 Rows)



-- Checking for NULL entries

SELECT *
FROM SQL_SSMS_Portfolio_3..Reviews
WHERE listing_id IS NULL
	OR id IS NULL
	OR reviewer_id IS NULL
	OR reviewer_name IS NULL
	OR comments IS NULL
	OR NewDate IS NULL		-- 93 NULL entries present only in Comment Field.
							-- We let go of it since a review can be given without posting a comment.



-- Replacing NULL Comments with '-' Comments

SELECT *, ISNULL(comments,'-') AS NewComments		-- Check if ISNULL is giving required result
FROM SQL_SSMS_Portfolio_3..Reviews
WHERE comments IS NULL

UPDATE SQL_SSMS_Portfolio_3..Reviews		-- Making final update on the column
SET comments = ISNULL(comments,'-')



-- This Data Table is Fully Cleaned and Good to go for future Data analysis!

--------------------------------------------------------------------------------------------------------------------------------