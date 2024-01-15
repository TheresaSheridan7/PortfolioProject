/*
PortfolioProject - Cleaning Data using SQL queries
*/


SELECT *
FROM PortfolioProject.dbo.NashvilleHousing


-- Standardise Date Format
SELECT SaleDate, CONVERT(Date, SaleDate)
FROM PortfolioProject.dbo.NashvilleHousing

UPDATE PortfolioProject.dbo.NashvilleHousing
SET SaleDate = CONVERT(Date, SaleDate)


--Add a new column SaleDateConverted as Date
ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD SaleDateConverted Date

UPDATE PortfolioProject.dbo.NashvilleHousing
SET SaleDateConverted = CONVERT(Date, SaleDate)

SELECT SaleDate, SaleDateConverted
FROM PortfolioProject.dbo.NashvilleHousing


--Populate Property Address data
--Found PropertyAddress column with NULL value
SELECT *
FROM PortfolioProject.dbo.NashvilleHousing
Where PropertyAddress is NULL

SELECT *
FROM PortfolioProject.dbo.NashvilleHousing
--Where PropertyAddress is NULL
ORDER BY  ParcelID

SELECT a.[UniqueID], a.ParcelID, a.PropertyAddress, b.[UniqueID], b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject.dbo.NashvilleHousing a
JOIN PortfolioProject.dbo.NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID] <> b.[UniqueID]
Where a.PropertyAddress is NULL


--UPDATE  records where PropertyAddress is NULL with the same address as same ParcelID
UPDATE  a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject.dbo.NashvilleHousing a
JOIN PortfolioProject.dbo.NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID] <> b.[UniqueID]
Where a.PropertyAddress is NULL


--Breaking out PropertyAddress into Individual columns (Address, City, State)
SELECT PropertyAddress
FROM PortfolioProject.dbo.NashvilleHousing

SELECT 
Substring(PropertyAddress, 1, CHARINDEX(',',PropertyAddress)-1) as Address
, Substring(PropertyAddress, CHARINDEX(',',PropertyAddress)+1, LEN(PropertyAddress)) as Address
FROM PortfolioProject.dbo.NashvilleHousing


--Add 2 new columns for PropertyAddress
ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD PropertySplitAddress NVARCHAR(255);

UPDATE  PortfolioProject.dbo.NashvilleHousing
SET PropertySplitAddress = Substring(PropertyAddress, 1, CHARINDEX(',',PropertyAddress)-1)

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD PropertySplitCity NVARCHAR(255);

UPDATE  PortfolioProject.dbo.NashvilleHousing
SET PropertySplitCity = Substring(PropertyAddress, CHARINDEX(',',PropertyAddress)+1, LEN(PropertyAddress))

SELECT *
FROM PortfolioProject.dbo.NashvilleHousing


--Breaking out OwnerAddress into Individual columns (Address, City, State)
SELECT OwnerAddress
FROM PortfolioProject.dbo.NashvilleHousing

SELECT
 PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)
,PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)
,PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM PortfolioProject.dbo.NashvilleHousing


ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD OwnerSplitAddress NVARCHAR(255);

UPDATE  PortfolioProject.dbo.NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)


ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD OwnerSplitCity NVARCHAR(255);

UPDATE PortfolioProject.dbo.NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)


ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD OwnerSplitState NVARCHAR(255);

UPDATE PortfolioProject.dbo.NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

-- Change Y and N in "Sold as Vacant" field
SELECT Distinct(SoldAsVacant), Count(SoldAsVacant)
FROM PortfolioProject.dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2


SELECT SoldAsVacant
,	Case When SoldAsVacant = 'Y' THEN 'Yes'
		 When SoldAsVacant = 'N' THEN 'No'
		 ELSE SoldAsVacant
		 END
FROM PortfolioProject.dbo.NashvilleHousing

UPDATE PortfolioProject.dbo.NashvilleHousing
SET SoldAsVacant = Case When SoldAsVacant = 'Y' THEN 'Yes'
		 When SoldAsVacant = 'N' THEN 'No'
		 ELSE SoldAsVacant
		 END


-- Remove Duplicates using ROW_NUMBER() and OVER PARTITION BY 
WITH RowNumCTE AS (
SELECT *,
	ROW_NUMBER() OVER(
	PARTITION BY ParcelID,
				PropertyAddress,
				SalePrice,
				SaleDate,
				LegalReference
				ORDER BY 
					UniqueID
					) row_num
FROM PortfolioProject.dbo.NashvilleHousing
)

SELECT * 
FROM RowNumCTE
Where row_num > 1
ORDER BY PropertyAddress

-- NOTE : Deleting records in CTE (RowNumCTE), removes record FROM the original table (PortfolioProject.dbo.NashvilleHousing)
DELETE  
FROM RowNumCTE
Where row_num > 1


--Delete Unused Columns
SELECT * 
FROM PortfolioProject.dbo.NashvilleHousing

ALTER Table PortfolioProject.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress

ALTER Table PortfolioProject.dbo.NashvilleHousing
DROP COLUMN SaleDate


/*
-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
-- Importing Data using OPENROWSET and BULK INSERT	

-- The following code could be used to bulk inert data FROM csv file to sql server. 
-- Note: To bulk insert a CSV files to a SQL table that dos not exist, we may need to create a table irst.


--  More advanced and looks cooler, but have to configure server appropriately to do correctly
--  Wanted to provide this in case you wanted to try it


sp_configure 'show advanced options', 1;
RECONFIGURE;
GO
sp_configure 'Ad Hoc Distributed Queries', 1;
RECONFIGURE;
GO

USE PortfolioProject 

GO 

EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'AllowInProcess', 1 

GO 

EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'DynamicParameters', 1 

GO 


-- Using BULK INSERT
USE PortfolioProject;
GO
BULK INSERT nashvilleHousingFROM 'C:\temp\Nashville Housing Data for Data Cleaning.csv'
   WITH (
      FIELDTERMINATOR = ',',
      ROWTERMINATOR = '\n'
);
GO

---- Using OPENROWSET
USE PortfolioProject.dbo.NashvilleHousing;
GO
SELECT * INTO nashvilleHousing
FROM OPENROWSET('Microsoft.ACE.OLEDB.12.0',
--    'Excel 12.0; Database=C:\Temp\Nashville Housing Data for Data Cleaning Project.csv', [Sheet1$]);
    'Excel 12.0; Database=C:\Temp\Nashville Housing Data for Data Cleaning.csv', [Sheet1$]);
GO


*/








