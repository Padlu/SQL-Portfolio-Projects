
  /*

  SQL based Data Cleaning for NashvilleHousing Data

  SQL skills used: JOINS, CTE, ISNULL(), String Functions, conditional CASE statement, Converting data types, RENAME, UPDATE, ALTER TABLE, DROP

  */

  ------------------------------------------------------------------------------------------------

  -- Standardize Date Format of SaleDate column
  -- Remove unnecessary time part from it



  SELECT SaleDate, CONVERT(date, SaleDate) as NewSaleDate
  FROM SQL_SSMS_Portfolio_2..NashvilleHousing



  -- We Update the table with this new column

  UPDATE NashvilleHousing
  SET SaleDate = CONVERT(date, SaleDate)

  SELECT SaleDate
  FROM SQL_SSMS_Portfolio_2..NashvilleHousing



  -- Direct UPDATE not working so trying another method by using ALTER TABLE

  ALTER TABLE NashvilleHousing
  ADD NewSaleDate Date

  UPDATE NashvilleHousing
  SET NewSaleDate = CONVERT(date, SaleDate)

  SELECT NewSaleDate
  FROM SQL_SSMS_Portfolio_2..NashvilleHousing


  ------------------------------------------------------------------------------------------------

  -- Populate the NULL Property Address entries

  SELECT PropertyAddress
  FROM SQL_SSMS_Portfolio_2..NashvilleHousing

  /* 
  
  In Real estate data, 99.99% chance is that property address cannot be NULL.
  So we need to rectify it.

  */


  SELECT *
  FROM SQL_SSMS_Portfolio_2..NashvilleHousing


  /* 
  
  We see that there's a ParcelID column unique to each property address and also a UniqueID for each entry.
 
  We can join the same table to itself on these two attributes such that uniqueID is not equal. 
  
  This will make sure that no same entries are joined and null addresses will be adjacent to real addresses for that Parcel ID

  */



  SELECT n1.[UniqueID ], n1.ParcelID, n1.PropertyAddress, n2.[UniqueID ], n2.ParcelID, n2.PropertyAddress
  FROM SQL_SSMS_Portfolio_2..NashvilleHousing n1
  JOIN SQL_SSMS_Portfolio_2..NashvilleHousing n2
	ON n1.ParcelID = n2.ParcelID
	AND n1.[UniqueID ] <> n2.[UniqueID ]
  WHERE n1.PropertyAddress is null
  ORDER BY n1.ParcelID



  -- Populate this column with the one on the n2 side by using ISNULL Function.

  SELECT n1.[UniqueID ], n1.ParcelID, n1.PropertyAddress, n2.[UniqueID ], n2.ParcelID, n2.PropertyAddress, 
	ISNULL(n1.PropertyAddress, n2.PropertyAddress)
  FROM SQL_SSMS_Portfolio_2..NashvilleHousing n1
  JOIN SQL_SSMS_Portfolio_2..NashvilleHousing n2
	ON n1.ParcelID = n2.ParcelID
	AND n1.[UniqueID ] <> n2.[UniqueID ]
  WHERE n1.PropertyAddress is null
  ORDER BY n1.ParcelID



  -- Make a final update in the table.

  UPDATE n1
  SET PropertyAddress = ISNULL(n1.PropertyAddress, n2.PropertyAddress)
  FROM SQL_SSMS_Portfolio_2..NashvilleHousing n1
  JOIN SQL_SSMS_Portfolio_2..NashvilleHousing n2
	ON n1.ParcelID = n2.ParcelID
	AND n1.[UniqueID ] <> n2.[UniqueID ]
  WHERE n1.PropertyAddress is null

  -- To check we run the previous query again and it has been updated as we wanted.  Nice Job!

  ------------------------------------------------------------------------------------------------

  -- Breaking out Address into individual columns to have more usability of the data (Address, City, State)



  /* For Property Address */

  SELECT PropertyAddress
  FROM SQL_SSMS_Portfolio_2..NashvilleHousing



  -- For Street Address --

  SELECT PropertyAddress, SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) as Address
  FROM SQL_SSMS_Portfolio_2..NashvilleHousing



  -- For City --

  SELECT PropertyAddress, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) as AddressCity
  FROM SQL_SSMS_Portfolio_2..NashvilleHousing



  -- We UPDATE this in the real Table

  ALTER TABLE NashvilleHousing
  ADD Address nvarchar(255), AddressCity nvarchar(255)

  UPDATE NashvilleHousing
  SET Address = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1), 
	AddressCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))


  SELECT * 
  FROM SQL_SSMS_Portfolio_2..NashvilleHousing


	/*
	-- Renaming the columns to PAddress and PAddressCity

	EXEC sp_RENAME 'NashvilleHousing.Address', 'PAddress', 'COLUMN'
	EXEC sp_RENAME 'NashvilleHousing.AddressCity', 'PAddressCity', 'COLUMN'
	*/



  /* Owner Address */

  -- Performing same operation using PARSENAME()

  SELECT OwnerAddress
  FROM SQL_SSMS_Portfolio_2..NashvilleHousing



  SELECT PARSENAME(REPLACE(OwnerAddress,',','.'), 1)  -- Replacing ',' w/ '.' as Parsename looks for period as the delimiter
  FROM SQL_SSMS_Portfolio_2..NashvilleHousing



  SELECT PARSENAME(REPLACE(OwnerAddress,',','.'), 3) as OAddress,  -- Street
	  PARSENAME(REPLACE(OwnerAddress,',','.'), 2) as OAddressCity,   -- City
	  PARSENAME(REPLACE(OwnerAddress,',','.'), 1) as OAddressState   -- State
  FROM SQL_SSMS_Portfolio_2..NashvilleHousing



  -- We UPDATE the main Table

  ALTER TABLE NashvilleHousing
  ADD OAddress nvarchar(255), OAddressCity nvarchar(255), OAddressState nvarchar(255)

  UPDATE NashvilleHousing
  SET OAddress = PARSENAME(REPLACE(OwnerAddress,',','.'), 3), 
	OAddressCity = PARSENAME(REPLACE(OwnerAddress,',','.'), 2),
	OAddressState = PARSENAME(REPLACE(OwnerAddress,',','.'), 1)



  SELECT * 
  FROM SQL_SSMS_Portfolio_2..NashvilleHousing

  -- Perfectly Done!


  ------------------------------------------------------------------------------------------------
  -- Standardizing values in "SoldAsVacant" Field ('y' -> 'Yes' and 'n' -> 'No')



  SELECT DISTINCT SoldAsVacant
  FROM SQL_SSMS_Portfolio_2..NashvilleHousing



  -- Understanding variable using DISTINCT and COUNT

  SELECT DISTINCT SoldAsVacant, COUNT(SoldAsVacant) as Count_
  FROM SQL_SSMS_Portfolio_2..NashvilleHousing
  GROUP BY SoldAsVacant
  ORDER BY 2

/*

  We see that only a few out of all the entries are unreliable. But, still we need to make this change for optimal use of the data.
  For this we use CASE method When value is 'Y' Then put it as 'Yes' and When 'N' Then 'No'

*/



  SELECT SoldAsVacant,
	CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	     WHEN SoldAsVacant = 'N' THEN 'No'
		 ELSE SoldAsVacant
		 END as NewSoldAsVacant
  FROM SQL_SSMS_Portfolio_2..NashvilleHousing



  -- We UPDATE the main Table.

  UPDATE NashvilleHousing
  SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
						  WHEN SoldAsVacant = 'N' THEN 'No'
						  ELSE SoldAsVacant
						  END

  ------------------------------------------------------------------------------------------------

  -- Removing Duplicates (Not a good practice to delete data from the actual database. But, here I'm doing it just to showcase my knowledge)

/*

  This can be done using a Window function to first select the columns on which we base our duplicate rows and to give them a count
  Then we use a CTE to delete the rows with count >1

*/



  SELECT *, (ROW_NUMBER() OVER
	(PARTITION BY ParcelID,
				PropertyAddress,
				SalePrice,
				SaleDate,
				LegalReference
				ORDER BY UniqueID)
	) as RowNum
  FROM SQL_SSMS_Portfolio_2..NashvilleHousing


  -- Using CTE, WHERE and DELETE to remove duplicates

  WITH DuplicateRowNum AS (
  SELECT *, (ROW_NUMBER() OVER
	(PARTITION BY ParcelID,
				PropertyAddress,
				SalePrice,
				SaleDate,
				LegalReference
				ORDER BY UniqueID)
	) as RowNum
  FROM SQL_SSMS_Portfolio_2..NashvilleHousing
  )
  DELETE
  FROM DuplicateRowNum
  WHERE RowNum > 1


  -- We checked by running the previous query that no duplicates are present now.
  -- Nice Job Done!


  ------------------------------------------------------------------------------------------------

  -- Deleting Unused Columns

  SELECT * 
  FROM SQL_SSMS_Portfolio_2..NashvilleHousing



  -- As we created new and usable addresses columns before, let's first get rid of the old address columns

  ALTER TABLE NashvilleHousing
  DROP COLUMN PropertyAddress, OwnerAddress, TaxDistrict



  -- Let's also get rid of SaleDate

  ALTER TABLE NashvilleHousing
  DROP COLUMN SaleDate