	/* AIRBNB DATA CLEANING */

	/* LISTING TABLE */

--------------------------------------------------------------------------------------------------------------------------------

SELECT *
FROM SQL_SSMS_Portfolio_3..Listings		-- 3384 Rows



---- Neighbourhood_overview has NULL values. Replace w/ '-'
---- Host_about has NULL values. Replace w/ '-'
---- Host_neighbourhood has NULL values. Can replace w/ neighbourhood_cleansed values as they overlap mostly
---- Neighbourhood has NULL values. Replace it w/ suitable string
---- Neighbourhood_group_cleansed is full of NULL values. Drop it.
---- Calendar_updated field is NULL. Drop it.
---- License field is NULL. Drop it.
---- Dropping unhelpful URL columns
---- Host_response_rate and Host_acceptance_rate has NULL values. Replace w/ AVG of respective fields
---- Host_is_superhost has values 't' and'f'
---- Host_has_profile_pic has values 't' and'f'
---- Host_identity_verified has values 't' and'f'
---- Has_availability has values 't' and 'f'
---- Instant_bookable has values 't' and 'f'
---- Bathroom field is NULL. Replace values from bathroom_text
---- Standardizing date fields: last_scraped, host_since, calendar_last_scraped, first_review, last_review



-- Checking for entire NULL fields from visual interpretted intuition

SELECT neighbourhood_group_cleansed, calendar_updated, license
FROM SQL_SSMS_Portfolio_3..Listings
WHERE neighbourhood_group_cleansed IS NOT NULL
	OR calendar_updated IS NOT NULL
	OR license IS NOT NULL		-- These 3 fields are entirely NULL.

ALTER TABLE SQL_SSMS_Portfolio_3..Listings		-- Thus, we DROP them entirely from the Listings table.
DROP COLUMN neighbourhood_group_cleansed, calendar_updated, license

SELECT TOP 20 *		-- Double Checking if the above Drop query worked
FROM SQL_SSMS_Portfolio_3..Listings



-- Dropping url columns as they are not use for us.

ALTER TABLE SQL_SSMS_Portfolio_3..Listings
DROP COLUMN listing_url, picture_url, host_url, host_thumbnail_url, host_picture_url



-- Checking NVARCHAR columns with NULL values

---- host_location:8
---- host_neighbourhood: 1900
---- neighbourhood: 1603
---- name:1
---- bathrooms_text: 6
---- neighborhood_overview: 1603
---- description:125
---- host_about: 1694


SELECT SUM(CASE WHEN name IS NULL THEN 1 ELSE 0 END) AS Name_Count,
	SUM(CASE WHEN neighborhood_overview IS NULL THEN 1 ELSE 0 END) AS Neighborhood_Overview_Count,
	SUM(CASE WHEN description IS NULL THEN 1 ELSE 0 END) AS Description_Count,
	SUM(CASE WHEN host_location IS NULL THEN 1 ELSE 0 END) AS Host_Location_Count,
	SUM(CASE WHEN host_about IS NULL THEN 1 ELSE 0 END) AS Host_About_Count,
	SUM(CASE WHEN bathrooms_text IS NULL THEN 1 ELSE 0 END) AS Bathrooms_Text_Count,
	SUM(CASE WHEN host_neighbourhood IS NULL THEN 1 ELSE 0 END) AS Host_Neighborhood_Count,
	SUM(CASE WHEN neighbourhood IS NULL THEN 1 ELSE 0 END) AS Neighbourhood_Count
FROM SQL_SSMS_Portfolio_3..Listings



-- Replacing Neighborhood_Overview, Description and Host_About NULL values with '-'

SELECT neighborhood_overview, ISNULL(neighborhood_overview,'-'), description, ISNULL(description,'-'),
	host_about, ISNULL(host_about,'-')
FROM SQL_SSMS_Portfolio_3..Listings		-- Provides required result

UPDATE SQL_SSMS_Portfolio_3..Listings		-- Make final Replace UPDATE on the table
SET neighborhood_overview = ISNULL(neighborhood_overview,'-'),
	description = ISNULL(description,'-'),
	host_about = ISNULL(host_about,'-')

SELECT TOP 100 *		-- Double Checking
FROM SQL_SSMS_Portfolio_3..Listings



-- Replacing Bathrooms_text NULL values with '0 bath'

SELECT bathrooms_text, ISNULL(bathrooms_text,'0 bath')
FROM SQL_SSMS_Portfolio_3..Listings
WHERE bathrooms_text IS NULL		-- Gives the result as needed

UPDATE SQL_SSMS_Portfolio_3..Listings		-- Make final Replace UPDATE on the table
SET bathrooms_text = ISNULL(bathrooms_text,'0 bath')



-- Replacing 1 name NULL value with 'N/A'

UPDATE SQL_SSMS_Portfolio_3..Listings		-- Make final Replace UPDATE on the table
SET name = ISNULL(name,'N/A')



-- Replacing NULL values in neighbourhood with 'Oslo, Norway'
	-- We do this because by careful visual examination of the columns neighbourhood and neighbourhood_cleansed
	-- shows that all the neighbourhood is from norway.
	-- Also, neighbourhood_cleansed field is an updated field on neighbourhood I think.
	-- So we can rename the neighbourhood column to City, Country or split them eventually.

UPDATE SQL_SSMS_Portfolio_3..Listings		-- Make final Replace UPDATE on the table
SET neighbourhood = ISNULL(neighbourhood,'Oslo, Norway')



-- Checking if host_neighborhood can be replaced with neighbourhood_cleansed

SELECT host_location, host_neighbourhood, neighbourhood, neighbourhood_cleansed
FROM SQL_SSMS_Portfolio_3..Listings
WHERE host_location = neighbourhood
	AND host_neighbourhood IS NULL		-- 62 rows. This means host is living in same location to that of the listed property
										-- We replace these rows with values of neighbourhood_cleansed.

UPDATE SQL_SSMS_Portfolio_3..Listings
SET host_neighbourhood = ISNULL(host_neighbourhood,neighbourhood_cleansed)
WHERE host_location = neighbourhood
	AND host_neighbourhood IS NULL		-- 62 rows were replaced with correct values.
										-- Now, let's look at other NULL values.

SELECT host_location, host_neighbourhood, neighbourhood, neighbourhood_cleansed
FROM SQL_SSMS_Portfolio_3..Listings
WHERE host_neighbourhood IS NULL		

-- Looks like majority of hosts live in Oslo, Norway with still having NULLs in neighbourhood
-- To rectify this we'll first replace those NULL entries where host_location has '%Oslo, Norway' 
	-- We'll replace the NULL values with the starting Municipality word of the host_location
	-- And, for those words having 'Oslo' as Municipality will be replaced by respective neighbourhood_cleansed Municipalities

/*		PARSENAME IS NOT GIVING CORRECT RESULTS SO WE'LL MOVE ON WITH SUBSTRING()

SELECT host_location,
		PARSENAME(REPLACE(host_location, ',','.'), 1) AS HL1,
		PARSENAME(REPLACE(host_location, ',','.'), 2) AS HL2,
		host_neighbourhood,
	CASE WHEN PARSENAME(REPLACE(host_location, ',','.'), 1) = PARSENAME(REPLACE(neighbourhood,',','.'), 1)
		AND PARSENAME(REPLACE(host_location, ',','.'), 2) = PARSENAME(REPLACE(neighbourhood,',','.'), 2)
		THEN ISNULL(host_neighbourhood, neighbourhood_cleansed)
		ELSE ISNULL(host_neighbourhood, SUBSTRING(host_location, 1, CHARINDEX(',', host_location)))
		END AS New_Host_Neighbourhood,
	neighbourhood,
		PARSENAME(REPLACE(neighbourhood, ',','.'), 1) AS N1,
		PARSENAME(REPLACE(neighbourhood, ',','.'), 2) AS N2,
		neighbourhood_cleansed
FROM SQL_SSMS_Portfolio_3..Listings
WHERE host_neighbourhood IS NULL

*/


-- // Put 4.5+ hrs in this one!
SELECT host_location, host_neighbourhood,
	CASE 
		WHEN LEN(host_location) > 14 
			AND SUBSTRING(host_location, LEN(host_location) - 11, LEN(host_location)) = 'Oslo, Norway'
			AND SUBSTRING(host_location, 1, LEN(host_location) - 14) <> 'Oslo'  -- First municipality is different
		THEN ISNULL(host_neighbourhood, SUBSTRING(host_location, 1, LEN(host_location) - 14)) 
		WHEN LEN(host_location) > 11 
			AND LEN(neighbourhood) > 11
			AND SUBSTRING(host_location, LEN(host_location) - 11, LEN(host_location))  -- Getting substring Oslo, Norway
				= SUBSTRING(neighbourhood, LEN(neighbourhood) - 11, LEN(neighbourhood))
		THEN ISNULL(host_neighbourhood, neighbourhood_cleansed)
		WHEN CHARINDEX(',', host_location) = 0 THEN ISNULL(host_neighbourhood, host_location)
		ELSE ISNULL(host_neighbourhood, SUBSTRING(host_location, 1, CHARINDEX(',', host_location) -1))
		END AS New_Host_Neighbourhood,
	neighbourhood, neighbourhood_cleansed
FROM SQL_SSMS_Portfolio_3..Listings
WHERE host_neighbourhood IS NULL



UPDATE SQL_SSMS_Portfolio_3..Listings		-- Making Final Update to Remaining NULL Host_Neighbourhood entries
SET host_neighbourhood = 
		CASE 
			WHEN LEN(host_location) > 14 
				AND SUBSTRING(host_location, LEN(host_location) - 11, LEN(host_location)) = 'Oslo, Norway'
				AND SUBSTRING(host_location, 1, LEN(host_location) - 14) <> 'Oslo'  -- First municipality is different
			THEN ISNULL(host_neighbourhood, SUBSTRING(host_location, 1, LEN(host_location) - 14)) 
			WHEN LEN(host_location) > 11 
				AND LEN(neighbourhood) > 11
				AND SUBSTRING(host_location, LEN(host_location) - 11, LEN(host_location))  -- Getting substring Oslo, Norway
					= SUBSTRING(neighbourhood, LEN(neighbourhood) - 11, LEN(neighbourhood))
			THEN ISNULL(host_neighbourhood, neighbourhood_cleansed)
			WHEN CHARINDEX(',', host_location) = 0 THEN ISNULL(host_neighbourhood, host_location)
			ELSE ISNULL(host_neighbourhood, SUBSTRING(host_location, 1, CHARINDEX(',', host_location) -1))
			END
WHERE host_neighbourhood IS NULL


-- Replacing Remaining NULL values in Host_Location and Host_Neighbourhood with 'N/A'

UPDATE SQL_SSMS_Portfolio_3..Listings		-- Replacing one NULL entry with correct Oslo, Norway entry
SET host_location = neighbourhood
WHERE host_location IS NULL
	AND host_neighbourhood IS NOT NULL

UPDATE SQL_SSMS_Portfolio_3..Listings		-- Replacing rest 7 NULL entries for both fields as 'N/A'
SET host_location = 'N/A',
	host_neighbourhood = 'N/A'
WHERE host_location IS NULL
	AND host_neighbourhood IS NULL



/*
	Replacing 't' and 'f' w/ 'True' and 'False' for fields Host_is_superhost, Host_has_profile_pic,
	Host_identity_verified, Has_availability, and Instant_bookable to standardize and make them easy to interpret
*/

UPDATE SQL_SSMS_Portfolio_3..Listings		
SET host_is_superhost = CASE WHEN host_is_superhost = 't' THEN 'True'
		WHEN host_is_superhost = 'f' THEN 'False'
		ELSE host_is_superhost
		END,
	host_has_profile_pic = CASE WHEN host_has_profile_pic = 't' THEN 'True'
		WHEN host_has_profile_pic = 'f' THEN 'False'
		ELSE host_has_profile_pic
		END,
	host_identity_verified = CASE WHEN host_identity_verified = 't' THEN 'True'
		WHEN host_identity_verified = 'f' THEN 'False'
		ELSE host_identity_verified
		END,
	has_availability = CASE WHEN has_availability = 't' THEN 'True'
		WHEN has_availability = 'f' THEN 'False'
		ELSE has_availability
		END,
	instant_bookable = CASE WHEN instant_bookable = 't' THEN 'True'
		WHEN instant_bookable = 'f' THEN 'False'
		ELSE instant_bookable
		END

SELECT TOP 20 *			-- Check if the values are updated
FROM SQL_SSMS_Portfolio_3..Listings

SELECT DISTINCT host_is_superhost, host_has_profile_pic,
	host_identity_verified, has_availability, instant_bookable
FROM SQL_SSMS_Portfolio_3..Listings



-- Replace NULL values in host_response_rate and host_acceptance_rate w/ respective field's AVG

	-- // Using a cheap method currently due time restraint
SELECT bathrooms, AVG(host_response_rate) AS avg_hrr, AVG(host_acceptance_rate) AS avg_har
FROM SQL_SSMS_Portfolio_3..Listings
GROUP BY bathrooms	-- AVG HRR: 0.8999 AND AVG HAR: 0.6699

UPDATE SQL_SSMS_Portfolio_3..Listings
SET host_response_rate = ISNULL(host_response_rate, 0.8999),
	host_acceptance_rate = ISNULL(host_acceptance_rate, 0.6699)

SELECT host_response_rate, host_acceptance_rate		-- Check if correctly updated
FROM SQL_SSMS_Portfolio_3..Listings
WHERE host_response_rate IS NULL
	OR host_acceptance_rate IS NULL



-- Removing unhelpful time part from date fields of last_scraped, host_since, calendar_last_scraped, first_review, last_review

ALTER TABLE SQL_SSMS_Portfolio_3..Listings
ADD New_Last_Scraped DATE,
	New_Host_Since DATE,
	New_Calendar_Last_Scraped DATE,
	New_First_Review DATE,
	New_Last_Review DATE

UPDATE SQL_SSMS_Portfolio_3..Listings
SET New_Last_Scraped = CONVERT(DATE,last_scraped), 
	New_Host_Since = CONVERT(DATE,host_since), 
	New_Calendar_Last_Scraped = CONVERT(DATE,calendar_last_scraped), 
	New_First_Review = CONVERT(DATE,first_review), 
	New_Last_Review = CONVERT(DATE,last_review)

SELECT TOP 100 *		-- Double check if UPDATEd and ALTERed
FROM SQL_SSMS_Portfolio_3..Listings

ALTER TABLE SQL_SSMS_Portfolio_3..Listings
DROP COLUMN last_scraped, host_since, calendar_last_scraped, first_review, last_review



-- Replacing NULL values of bathrooms with numeric values from bathrooms_text field

SELECT DISTINCT bathrooms, bathrooms_text
FROM SQL_SSMS_Portfolio_3..Listings

SELECT DISTINCT bathrooms, bathrooms_text, TRIM('shared baths priv lf-' FROM bathrooms_text) AS NewBT
FROM SQL_SSMS_Portfolio_3..Listings

WITH Trimed_BT AS
(
	SELECT bathrooms, bathrooms_text, TRIM('shared baths priv lf-' FROM bathrooms_text) AS NewBT
	FROM SQL_SSMS_Portfolio_3..Listings
)
SELECT bathrooms, bathrooms_text, NewBT, CASE WHEN NewBT = '' THEN ISNULL(bathrooms, 0.5) 
												ELSE ISNULL(bathrooms, CONVERT(float, NewBT))
												END AS New_Bathrooms
FROM Trimed_BT		-- Gives the desired floating values for bathrooms.
					-- Now, we make final UPDATE on the table.



WITH Trimed_BT AS
(
	SELECT bathrooms, bathrooms_text, TRIM('shared baths priv lf-' FROM bathrooms_text) AS NewBT
	FROM SQL_SSMS_Portfolio_3..Listings
)
UPDATE Trimed_BT		-- UPDATING CTE will actually update the Listing Table! As it is a common table!
SET bathrooms = CASE WHEN NewBT = '' THEN ISNULL(bathrooms, CONVERT(float, 0.5)) 
					ELSE ISNULL(bathrooms, CONVERT(float, NewBT))
					END

SELECT bathrooms, bathrooms_text		-- Double Check. All values updated correctly. Well Done!
FROM SQL_SSMS_Portfolio_3..Listings
WHERE bathrooms IS NULL


-- Columns that are dealt with missing values:
	-- id, scrape_id, name, description, neighborhood_overview, host_id, host_name, host_location, host_about, 
	-- host_response_time, host_response_rate, host_acceptance_rate, host_is_superhost, host_neighbourhood, 
	-- host_listings_count, host_total_listings_count, host_verifications, host_has_profile_pic, host_identity_verified,
	-- neighbourhood, neighbourhood_cleansed, latitude, longitude, property_type, room_type, bathrooms, bathrooms_text,
	-- accommodates, amenities, price, minimum_nights, maximum_nights, has_availability, 
	-- availability_30, availability_60, availability_90, availability_365,
	-- number_of_reviews, number_of_reviews_ltm, number_of_reviews_l30d, instant_bookable, calculated_host_listings_count, 
	-- calculated_host_listings_count_entire_homes, calculated_host_listings_count_private_rooms, 
	-- calculated_host_listings_shared_rooms, New_Last_Scraped, New_Host_Since, New_Calendar_Last_Scraped

SELECT *
FROM SQL_SSMS_Portfolio_3..Listings
WHERE New_Last_Scraped IS NULL 
	OR New_Host_Since is NULL
	OR New_Calendar_Last_Scraped is NULL




-- Columns with NULLs that are still to be dealt with: New_First_Review, New_Last_Review


-- Correcting missing values for bedrooms and beds

SELECT bedrooms, beds, id		-- 416 Rows of NULLs. Strangely almost all the NULLs are either in bedrooms OR in beds. 
FROM SQL_SSMS_Portfolio_3..Listings		-- Very few entries have NULLs in Both. We use this data to our advantage to rectify the NULLs.
WHERE bedrooms IS NULL
	OR beds IS NULL

UPDATE SQL_SSMS_Portfolio_3..Listings		-- We fill in same values for both the columns as most probable case of bnb
SET bedrooms = ISNULL(bedrooms, beds),
	beds = ISNULL(beds, bedrooms)
WHERE bedrooms IS NULL
	OR beds IS NULL

SELECT bedrooms, beds, id		-- No bnb has 0 rooms or 0 beds. That's obvious but make sure if the data is correct. 
FROM SQL_SSMS_Portfolio_3..Listings	
WHERE bedrooms <1
	OR beds <1

UPDATE SQL_SSMS_Portfolio_3..Listings		-- We fill the remaining 15 NULL entries as 1 for both 
SET bedrooms = ISNULL(bedrooms, CONVERT(numeric,1)),	-- as minimum bedrooms and beds as it is highly likely the case.
	beds = ISNULL(beds, CONVERT(numeric,1))
WHERE bedrooms IS NULL
	OR beds IS NULL



-- Correcting missing values for Review_Scores_ fields

SELECT id, review_scores_rating, review_scores_accuracy, review_scores_cleanliness, review_scores_checkin,
	review_scores_communication, review_scores_location, review_scores_value
FROM SQL_SSMS_Portfolio_3..Listings		-- 547 rows
WHERE review_scores_rating IS NULL
	OR review_scores_accuracy IS NULL
	OR review_scores_cleanliness IS NULL
	OR review_scores_checkin IS NULL
	OR review_scores_communication IS NULL
	OR review_scores_location IS NULL
	OR review_scores_value IS NULL

	/*
	
	Checking if rating score is avg of rest scores to see if we can replace nulls with ratings
	
	*/

SELECT id, review_scores_rating, review_scores_accuracy, review_scores_cleanliness, review_scores_checkin,
	review_scores_communication, review_scores_location, review_scores_value, 
	(review_scores_accuracy + review_scores_cleanliness + review_scores_checkin +
	review_scores_communication + review_scores_location + review_scores_value)/ 6.0 AS ratings
FROM SQL_SSMS_Portfolio_3..Listings		-- They are unrelated	

	-- Since All the ids are unique we know that the NULL values cannot be replaced with anything.
	-- Thus, we replace the NULLs with AVG values of respective columns.

WITH Temp_avg AS		-- Checking the AVGs using CTE
(
SELECT id, ROW_NUMBER() OVER (PARTITION BY id ORDER BY id) AS rnum, 
	review_scores_rating, review_scores_accuracy, review_scores_cleanliness, review_scores_checkin,
	review_scores_communication, review_scores_location, review_scores_value
	FROM SQL_SSMS_Portfolio_3..Listings
)
SELECT rnum, AVG(review_scores_rating) AS rsr, AVG(review_scores_accuracy) AS rsa, AVG(review_scores_cleanliness)  AS rsc,
	AVG(review_scores_checkin) AS rsch, AVG(review_scores_communication) AS rsco,
	AVG(review_scores_location) AS rsl, AVG(review_scores_value) AS rsv
FROM Temp_avg
GROUP BY rnum


WITH Temp_avg AS		-- Making a Final Update using 2 CTEs and one JOIN CTE
(
SELECT id, ROW_NUMBER() OVER (PARTITION BY id ORDER BY id) AS rnum, 
	review_scores_rating, review_scores_accuracy, review_scores_cleanliness, review_scores_checkin,
	review_scores_communication, review_scores_location, review_scores_value
FROM SQL_SSMS_Portfolio_3..Listings
), Temp_avg_grp AS
(
SELECT rnum, AVG(review_scores_rating) AS rsr, AVG(review_scores_accuracy) AS rsa, AVG(review_scores_cleanliness)  AS rsc,
	AVG(review_scores_checkin) AS rsch, AVG(review_scores_communication) AS rsco,
	AVG(review_scores_location) AS rsl, AVG(review_scores_value) AS rsv
FROM Temp_avg
GROUP BY rnum
), Temp_join AS
(
SELECT ta.id, ta.rnum, tag.rsr, tag.rsa, tag.rsc, tag.rsch, tag.rsco, tag.rsl, tag.rsv,
	ta.review_scores_rating, ta.review_scores_accuracy, ta.review_scores_cleanliness, ta.review_scores_checkin,
	ta.review_scores_communication, ta.review_scores_location, ta.review_scores_value
FROM Temp_avg ta LEFT JOIN Temp_avg_grp tag ON ta.rnum = tag.rnum
)
UPDATE Temp_join 
	SET review_scores_rating = ISNULL(review_scores_rating, rsr),
	review_scores_accuracy = ISNULL(review_scores_accuracy, rsa),
	review_scores_cleanliness = ISNULL(review_scores_cleanliness, rsc),
	review_scores_checkin = ISNULL(review_scores_checkin, rsch),
	review_scores_communication = ISNULL(review_scores_communication, rsco),
	review_scores_location = ISNULL(review_scores_location, rsl),
	review_scores_value = ISNULL(review_scores_value, rsv)



UPDATE SQL_SSMS_Portfolio_3..Listings		-- Rectifying the above update by making avgs to 0 When ratings is 0
SET review_scores_accuracy = CASE WHEN review_scores_rating = 0 THEN 0 ELSE review_scores_accuracy END, 
	review_scores_cleanliness = CASE WHEN review_scores_rating = 0 THEN 0 ELSE review_scores_cleanliness END, 
	review_scores_checkin = CASE WHEN review_scores_rating = 0 THEN 0 ELSE review_scores_checkin END,
	review_scores_communication = CASE WHEN review_scores_rating = 0 THEN 0 ELSE review_scores_communication END, 
	review_scores_location = CASE WHEN review_scores_rating = 0 THEN 0 ELSE review_scores_location END, 
	review_scores_value = CASE WHEN review_scores_rating = 0 THEN 0 ELSE review_scores_value END



SELECT id, review_scores_rating, review_scores_accuracy, review_scores_cleanliness, review_scores_checkin,
	review_scores_communication, review_scores_location, review_scores_value
FROM SQL_SSMS_Portfolio_3..Listings		-- All the Updates are correctly performed as desired! Well Done!



-- Checking Review_per_month and Number_of_reviews if they are same

SELECT reviews_per_month, number_of_reviews		-- These two columns seem to be correlated. Also, with an intuition it looks
FROM SQL_SSMS_Portfolio_3..Listings			-- like reviews_per_month is not more useful than number_of_reviews. Thus, we DROP it.

ALTER TABLE SQL_SSMS_Portfolio_3..Listings
DROP COLUMN reviews_per_month



-- Checking for New_First_Review and New_Last_Review columns

SELECT id, number_of_reviews, New_First_Review, New_Last_Review		-- 522 rows of VALID Nulls as number of reviews is  0 for all
FROM SQL_SSMS_Portfolio_3..Listings									-- We intentionally keep these NULL Values.
WHERE New_First_Review IS NULL OR New_Last_Review IS NULL



-- We now drop the rest unnecessary columns minimum_minimum_nights, maximum_minimum_nights, 
	-- minimum_maximum_nights, maximum_maximum_nights, minimum_nights_avg_ntm, and maximum_nights_avg_ntm

ALTER TABLE SQL_SSMS_Portfolio_3..Listings
DROP COLUMN minimum_minimum_nights, maximum_minimum_nights, minimum_maximum_nights, maximum_maximum_nights,
	minimum_nights_avg_ntm, maximum_nights_avg_ntm



-- We also will not need columns such as scrape_id, New_Last_Scraped and New_Calendar_Last_Scraped. We DROP them as well.

ALTER TABLE SQL_SSMS_Portfolio_3..Listings
DROP COLUMN scrape_id, New_Last_Scraped, New_Calendar_Last_Scraped


SELECT TOP 100 *		-- Check for what's still remaining in Cleaning the data.
FROM SQL_SSMS_Portfolio_3..Listings



-- Checking if host_listing_count and host_total_listing_count is redundant

SELECT *		-- Turns out they both are same. We drop the second column
FROM SQL_SSMS_Portfolio_3..Listings
WHERE host_listings_count <> host_total_listings_count

ALTER TABLE SQL_SSMS_Portfolio_3..Listings
DROP COLUMN host_total_listings_count



-- Correcting host_response_rate to 0 for those whose host_response_time is N/A.

UPDATE SQL_SSMS_Portfolio_3..Listings
SET host_response_rate = CASE WHEN host_response_time = 'N/A' THEN 0 ELSE host_response_rate END



-- Checking for INVALID Data for columns availability_<30<60<90<365, number_of_reviews_ 1>2>3, reviews_scores_ <5, 
	-- calculated_host_listings_count>1>2>3, minimum_nights<maximum_nights, accommodates<1

SELECT availability_30, availability_60, availability_90, availability_365
FROM SQL_SSMS_Portfolio_3..Listings
WHERE availability_30 > 30
	OR availability_60 > 60
	OR availability_90 > 90
	OR availability_365 > 365		-- Values are Valid



SELECT number_of_reviews, number_of_reviews_ltm, number_of_reviews_l30d
FROM SQL_SSMS_Portfolio_3..Listings
WHERE number_of_reviews < number_of_reviews_ltm
	OR number_of_reviews < number_of_reviews_l30d
	OR number_of_reviews_ltm < number_of_reviews_l30d		-- Values are Valid



SELECT review_scores_rating, review_scores_accuracy, review_scores_cleanliness, review_scores_checkin,
	review_scores_communication, review_scores_location, review_scores_value
FROM SQL_SSMS_Portfolio_3..Listings
WHERE review_scores_rating > 5
	OR review_scores_accuracy > 5
	OR review_scores_cleanliness > 5
	OR review_scores_checkin > 5
	OR review_scores_communication > 5
	OR review_scores_location > 5
	OR review_scores_value > 5		-- Values are Valid



SELECT calculated_host_listings_count, calculated_host_listings_count_entire_homes,
	calculated_host_listings_count_private_rooms, calculated_host_listings_count_shared_rooms
FROM SQL_SSMS_Portfolio_3..Listings
WHERE calculated_host_listings_count < calculated_host_listings_count_entire_homes
	OR calculated_host_listings_count < calculated_host_listings_count_private_rooms
	OR calculated_host_listings_count < calculated_host_listings_count_shared_rooms		-- Values are Valid



SELECT minimum_nights, maximum_nights
FROM SQL_SSMS_Portfolio_3..Listings
WHERE minimum_nights > maximum_nights		-- Values are Valid



SELECT *
FROM SQL_SSMS_Portfolio_3..Listings
WHERE accommodates < 1		-- 3 entries where Accommodates were 0 which doesn't seem correct.

-- it seems that 3rd entry had a lot of null values that we rectified and so can be deleted entirely
-- Also, the first 2 entries have 0s in bathrooms, baths, availabilty_, and only 1 as calculated_host_listing_counts. But,
	-- there are many reviews for these 2 properties which doesn't seem right.
	-- Thus, we remove these 3 entries.

DELETE
FROM SQL_SSMS_Portfolio_3..Listings
WHERE accommodates < 1		-- INVALID Data where accommodates < 1 is rectified.



-- We split the host_location and neighbourhood columns into City and Country

ALTER TABLE SQL_SSMS_Portfolio_3..Listings
ADD Host_Location_Municipality nvarchar(255),
	Host_Location_City nvarchar(255),
	Host_Location_Country nvarchar(255),
	Neighbourhood_Municipality nvarchar(255),
	Neighbourhood_City nvarchar(255),
	Neighbourhood_Country nvarchar(255)

SELECT host_location, CASE WHEN PARSENAME(REPLACE(host_location,',','.'), 3) IS NOT NULL 
							AND TRIM(' ,' FROM PARSENAME(REPLACE(host_location,',','.'), 3)) <> 'Oslo'
							THEN TRIM(' ,' FROM PARSENAME(REPLACE(host_location,',','.'), 3)) ELSE '' END AS HMun,
	CASE WHEN PARSENAME(REPLACE(host_location,',','.'), 2) IS NOT NULL 
			THEN TRIM(' ,' FROM PARSENAME(REPLACE(host_location,',','.'), 2)) ELSE '' END AS HCity,
	CASE WHEN PARSENAME(REPLACE(host_location,',','.'), 1) IS NOT NULL 
			AND LEN(TRIM(' ,' FROM PARSENAME(REPLACE(host_location,',','.'), 1))) > 2
			THEN TRIM(' ,' FROM PARSENAME(REPLACE(host_location,',','.'), 1)) 
			WHEN TRIM(' ,' FROM PARSENAME(REPLACE(host_location,',','.'), 1)) = 'NO' THEN 'Norway'
			WHEN TRIM(' ,' FROM PARSENAME(REPLACE(host_location,',','.'), 1)) = 'SE' THEN 'Sweden'
			WHEN TRIM(' ,' FROM PARSENAME(REPLACE(host_location,',','.'), 1)) = 'CH' THEN 'Switzerland'
			WHEN TRIM(' ,' FROM PARSENAME(REPLACE(host_location,',','.'), 1)) = 'CN' THEN 'China'
			WHEN TRIM(' ,' FROM PARSENAME(REPLACE(host_location,',','.'), 1)) = 'FI' THEN 'Finland'
			WHEN TRIM(' ,' FROM PARSENAME(REPLACE(host_location,',','.'), 1)) = 'FR' THEN 'France'
			WHEN TRIM(' ,' FROM PARSENAME(REPLACE(host_location,',','.'), 1)) = 'NP' THEN 'Nepal'
			WHEN TRIM(' ,' FROM PARSENAME(REPLACE(host_location,',','.'), 1)) = 'PT' THEN 'Portugal'
			WHEN TRIM(' ,' FROM PARSENAME(REPLACE(host_location,',','.'), 1)) = 'RU' THEN 'Russia'
			WHEN TRIM(' ,' FROM PARSENAME(REPLACE(host_location,',','.'), 1)) = 'SJ' THEN 'Svalbard and Jan Mayen'
			WHEN TRIM(' ,' FROM PARSENAME(REPLACE(host_location,',','.'), 1)) = 'US' THEN 'United States'
			ELSE '' END AS HCountry,
	CASE WHEN PARSENAME(REPLACE(neighbourhood,',','.'), 3) IS NOT NULL 
			AND TRIM(' ,' FROM PARSENAME(REPLACE(neighbourhood,',','.'), 3)) <> 'Oslo'
			THEN TRIM(' ,' FROM PARSENAME(REPLACE(neighbourhood,',','.'), 3)) ELSE '' END AS NMun,
	CASE WHEN PARSENAME(REPLACE(neighbourhood,',','.'), 2) IS NOT NULL 
			THEN TRIM(' ,' FROM PARSENAME(REPLACE(neighbourhood,',','.'), 2)) ELSE '' END AS NCity,
	CASE WHEN PARSENAME(REPLACE(neighbourhood,',','.'), 1) IS NOT NULL 
			THEN TRIM(' ,' FROM PARSENAME(REPLACE(neighbourhood,',','.'), 1)) ELSE '' END AS NCountry,
	host_neighbourhood, 
	neighbourhood, 
	neighbourhood_cleansed
FROM SQL_SSMS_Portfolio_3..Listings


UPDATE SQL_SSMS_Portfolio_3..Listings
SET Host_Location_Municipality = CASE WHEN PARSENAME(REPLACE(host_location,',','.'), 3) IS NOT NULL 
							AND TRIM(' ,' FROM PARSENAME(REPLACE(host_location,',','.'), 3)) <> 'Oslo'
							THEN TRIM(' ,' FROM PARSENAME(REPLACE(host_location,',','.'), 3)) ELSE '' END,
	Host_Location_City = CASE WHEN PARSENAME(REPLACE(host_location,',','.'), 2) IS NOT NULL 
							THEN TRIM(' ,' FROM PARSENAME(REPLACE(host_location,',','.'), 2)) ELSE '' END,
	Host_Location_Country = CASE WHEN PARSENAME(REPLACE(host_location,',','.'), 1) IS NOT NULL 
							AND LEN(TRIM(' ,' FROM PARSENAME(REPLACE(host_location,',','.'), 1))) > 2
							THEN TRIM(' ,' FROM PARSENAME(REPLACE(host_location,',','.'), 1)) 
							WHEN TRIM(' ,' FROM PARSENAME(REPLACE(host_location,',','.'), 1)) = 'NO' THEN 'Norway'
							WHEN TRIM(' ,' FROM PARSENAME(REPLACE(host_location,',','.'), 1)) = 'SE' THEN 'Sweden'
							WHEN TRIM(' ,' FROM PARSENAME(REPLACE(host_location,',','.'), 1)) = 'CH' THEN 'Switzerland'
							WHEN TRIM(' ,' FROM PARSENAME(REPLACE(host_location,',','.'), 1)) = 'CN' THEN 'China'
							WHEN TRIM(' ,' FROM PARSENAME(REPLACE(host_location,',','.'), 1)) = 'FI' THEN 'Finland'
							WHEN TRIM(' ,' FROM PARSENAME(REPLACE(host_location,',','.'), 1)) = 'FR' THEN 'France'
							WHEN TRIM(' ,' FROM PARSENAME(REPLACE(host_location,',','.'), 1)) = 'NP' THEN 'Nepal'
							WHEN TRIM(' ,' FROM PARSENAME(REPLACE(host_location,',','.'), 1)) = 'PT' THEN 'Portugal'
							WHEN TRIM(' ,' FROM PARSENAME(REPLACE(host_location,',','.'), 1)) = 'RU' THEN 'Russia'
							WHEN TRIM(' ,' FROM PARSENAME(REPLACE(host_location,',','.'), 1)) = 'SJ' THEN 'Svalbard and Jan Mayen'
							WHEN TRIM(' ,' FROM PARSENAME(REPLACE(host_location,',','.'), 1)) = 'US' THEN 'United States'
							ELSE '' END,
	Neighbourhood_Municipality = CASE WHEN PARSENAME(REPLACE(neighbourhood,',','.'), 3) IS NOT NULL 
							AND TRIM(' ,' FROM PARSENAME(REPLACE(neighbourhood,',','.'), 3)) <> 'Oslo'
							THEN TRIM(' ,' FROM PARSENAME(REPLACE(neighbourhood,',','.'), 3)) ELSE '' END,
	Neighbourhood_City = CASE WHEN PARSENAME(REPLACE(neighbourhood,',','.'), 2) IS NOT NULL 
			THEN TRIM(' ,' FROM PARSENAME(REPLACE(neighbourhood,',','.'), 2)) ELSE '' END,
	Neighbourhood_Country = CASE WHEN PARSENAME(REPLACE(neighbourhood,',','.'), 1) IS NOT NULL 
			THEN TRIM(' ,' FROM PARSENAME(REPLACE(neighbourhood,',','.'), 1)) ELSE '' END

	-- New Columns were added and correctly updated! Well Done!

SELECT *
FROM SQL_SSMS_Portfolio_3..Neighbourhoods

ALTER TABLE SQL_SSMS_Portfolio_3..Listings		-- Remove the Changed columns host_location and neighbourhood
DROP COLUMN host_location, neighbourhood 


-- We now correct the incorrect spellings in the neighbourhood columns of host and property

/*	Using CHARINDEX and REPLACE is not working. So we'll us Neighbourhood table to rectify the columns

SELECT id, Host_Location_Municipality, host_neighbourhood, 
	CASE WHEN CHARINDEX('º', l.host_neighbourhood) <> 0 THEN REPLACE(l.host_neighbourhood, '√º', 'ü')
		WHEN CHARINDEX('∏', l.host_neighbourhood) <> 0 THEN REPLACE(l.host_neighbourhood, '√∏', 'ø')
		WHEN CHARINDEX('ò', l.host_neighbourhood) <> 0 THEN REPLACE(l.host_neighbourhood, '√ò', 'Ø')
		ELSE l.host_neighbourhood END AS New_host_neighbourhood,
	CASE WHEN CHARINDEX('º', l.host_neighbourhood) <> 0 THEN 1 ELSE CHARINDEX('º', l.host_neighbourhood)
		END AS New_host_neighbourhood_TRUTH,
	Neighbourhood_Municipality, neighbourhood_cleansed
FROM SQL_SSMS_Portfolio_3..Listings l

*/ 

UPDATE l
SET l.Host_Location_Municipality = CASE WHEN l.Host_Location_Municipality = l.neighbourhood_cleansed
				THEN n.neighbourhood
				ELSE l.Host_Location_Municipality END,
	l.host_neighbourhood = CASE WHEN l.host_neighbourhood = l.neighbourhood_cleansed
				THEN n.neighbourhood
				ELSE l.host_neighbourhood END,
	l.Neighbourhood_Municipality = CASE WHEN l.Neighbourhood_Municipality = l.neighbourhood_cleansed
				THEN n.neighbourhood
				ELSE l.Neighbourhood_Municipality END,
	l.neighbourhood_cleansed = n.neighbourhood
FROM SQL_SSMS_Portfolio_3..Listings AS l 
	LEFT JOIN SQL_SSMS_Portfolio_3..Neighbourhoods n
	ON l.neighbourhood_cleansed = n.neighbourhood_cleansed

SELECT TOP 200 *
FROM SQL_SSMS_Portfolio_3..Listings		-- The incorrect spellings were corrected to best of our ability!
										-- We'll see how to do it in future due to time restrictions!



-- This Data Table is Fully Cleaned (EXCEPT for incorrect Spellings for now) 
-- and Good to go for future Data analysis!

--------------------------------------------------------------------------------------------------------------------------------
