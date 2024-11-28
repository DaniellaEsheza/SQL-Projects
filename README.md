# SQL-Data-Cleaning-Project

This repository contains a project focused on data cleaning and exploratory data analysis (EDA).

## Project Overview

This project focuses on cleaning and analyzing a dataset related to company layoffs. The primary objectives are to ensure the data is clean and standardized and to conduct exploratory data analysis (EDA) to uncover valuable insights.

## Table of Contents

### 

- [Project Overview](#project-overview)
- [Dataset](#dataset)
- [Steps for Data Cleaning](#steps-for-data-cleaning)
- [Exploratory Data Analysis (EDA)](#exploratory-data-analysis-eda)

## Dataset

The dataset used in this project includes detailed information on company layoffs, such as company names, locations, industries, total number of employees laid off, percentage of workforce affected, dates of layoffs, company stages, countries, and funds raised, all of which can be found in the "layoffs.csv" file.

## Steps for Data Cleaning

When cleaning data, the following steps are typically necessary:

1. Identifying and removing duplicates
2. Standardizing data and correcting any errors
3. Handling NULL values and  identifying inconsistent entries to improve data quality
4. Removing Unnecessary Columns or Rows

### 1. Identifying and Removing Duplicates

- Before starting the cleaning process, creating a staging table with the same data is essential to avoid modifying the original raw dataset.

#### Create/Insert data into staging

```sql
CREATE TABLE layoffs_staging
LIKE layoffs;

INSERT INTO layoffs_staging
SELECT *
FROM layoffs;
```
#### Identifying duplicates if any

- Since there is no unique identifying column, a row number will be generated to match against all columns.
```sql
SELECT *,
ROW_NUMBER() OVER (
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, date, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;
```
- Identifying and removing duplicates by partitioning the data and filtering out rows with row numbers greater than 1.
```sql
WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER (
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, date, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging)

SELECT*
FROM duplicate_cte
WHERE row_num > 1;
```
#### Removing duplicates

- Since a DELETE statement functions similarly to an UPDATE statement and a CTE cannot be updated, a staging2 database will be created to delete rows where the row number equals 2.
```sql
CREATE TABLE layoffs_staging2 (
`company` text,
`location` text,
`industry` text,
`total_laid_off` int DEFAULT NULL,
`percentage_laid_off` text,
`date` text,
`stage` text,
`country` text,
`funds_raised_millions` int DEFAULT NULL,
row_num INT
 ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO layoffs_staging2
SELECT
    company,
    location,
    industry,
    CASE
        WHEN total_laid_off = 'none' OR total_laid_off IS NULL THEN NULL
        ELSE CAST(total_laid_off AS DECIMAL(10,2))
    END AS total_laid_off,
    percentage_laid_off,
    date,
    stage,
    country,
    CASE
        WHEN funds_raised_millions = 'none' OR funds_raised_millions IS NULL THEN NULL
        ELSE CAST(funds_raised_millions AS DECIMAL(10,2))
    END AS funds_raised_millions,
    ROW_NUMBER() OVER (
        PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, date, stage, country, funds_raised_millions
    ) AS row_num
FROM layoffs_staging;

```
- Now that the staging2 database has been created, rows with a row number greater than 1 can be deleted.
```sql
SELECT *
FROM layoffs_staging2
WHERE row_num > 1;

DELETE
FROM layoffs_staging2
WHERE row_num > 1;
```
### 2. Standardizing Data

-  Inconsistent data formats can lead to errors in analysis. Standardization ensures consistency in data entries by trimming whitespace, standardizing industry names, managing location data, and formatting date fields.

#### Standardize company names by trimming spaces
```sql
UPDATE layoffs_staging2
SET company = TRIM(company);
```
- Verifying the change.
```sql
SELECT company, TRIM(company)
FROM layoffs_staging2;
```
#### Standardizing industry names

- Identifying industry names.
```sql
SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY 1;
```
- Standardizing 'Crypto' industry names.
```sql
UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';
```
- Verifying the change.
```sql
SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1;
```
#### Standardize country names by trimming unwanted characters

- Identifying distinct countries.
```sql
SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1;
```
- Standardizing country names by removing trailing periods.
```sql
UPDATE layoffs_staging
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';
```
- Verifying the change.
```sql
SELECT DISTINCT country, TRIM(TRAILING  '.' FROM country)
FROM layoffs_staging2
ORDER BY 1;
```
#### Formatting Date Fields

- Converting  `date` field to a DATE type
```sql
SELECT date,
STR_TO_DATE (date, '%m/%d/%Y') AS formatted_date
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET date = CASE
WHEN date = 'none' OR date IS NULL THEN NULL
ELSE STR_TO_DATE(date, '%m/%d/%Y')
END;
```
- Changing the column type of date to DATE
```sql
ALTER TABLE layoffs_staging2
MODIFY COLUMN date DATE;
```
### 3.  Handling NULL and Inconsistent Values

- NULL values and inconsistencies can significantly impact the quality of analysis
```sql
SELECT*
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

SELECT DISTINCT industry
FROM layoffs_staging2
;

UPDATE layoffs_staging2
SET industry = CASE
WHEN industry = 'none' THEN NULL
ELSE industry
END;

SELECT *
FROM layoffs_staging2
WHERE industry IS NULL
OR industry = '';

UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';

SELECT *
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
ON t1.company = t2.company
WHERE (t1.industry IS NULL OR t1.industry ='')
AND t2.industry IS NOT NULL;

UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
ON t1.company  = t2.company
SET t1.industry = t2.industry
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL;

SELECT*
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;
```
### 4.  Removing Unnecessary Columns or Rows
```sql
SELECT*
FROM layoffs_staging2;

ALTER TABLE layoffs_staging2
DROP COLUMN row_num;
```
## Exploratory Data Analysis (EDA)

EDA involves examining and summarizing a dataset to uncover patterns, detect anomalies, test hypotheses, and check assumptions. This exploratory data analysis provides  a comprehensive view of layoffs, highlighting key trends, affected sectors, and contributing companies.

- Each query addresses a specific analytical objective.

### a. Inspect the Dataset

- This query retrieves all columns and rows from the layoffs_staging2 table, providing a comprehensive view of the dataset's structure and contents:
```sql
SELECT *
FROM layoffs_staging2;
```
### b. Identify Maximum Layoffs

- This finds the highest number of employees laid off in a single instance and the maximum percentage of workforce reduction across all records:
```sql
SELECT MAX(total_laid_off), MAX(percentage_laid_off)
FROM layoffs_staging2;
```
### c. Companies with 100% Layoff Rate

- Identifying records of companies that laid off their entire workforce, ordered by their funding levels:
```sql
SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;
```
### d. Total Layoffs by Company, Industry and Country

- Calculating total layoffs per company, Industry and Country:
```sql
SELECT company, SUM(total_laid_off) AS total_layoffs
FROM layoffs_staging2
GROUP BY company
ORDER BY total_layoffs DESC;


SELECT industry, SUM(total_laid_off) AS industry_layoffs
FROM layoffs_staging2
GROUP BY industry
ORDER BY industry_layoffs DESC;

SELECT country, SUM(total_laid_off) AS country_layoffs
FROM layoffs_staging2
GROUP BY country
ORDER BY country_layoffs DESC;
```
### e. Date Range of Layoffs

- Identifying the earliest and latest dates of layoffs recorded in the dataset:
```sql
SELECT MIN(date) AS earliest_date, MAX(date) AS latest_date
FROM layoffs_staging2;
```
### f. Annual Layoff Trends

- Aggregating layoffs by year to observe annual trends:
```sql
SELECT YEAR(date) AS year, SUM(total_laid_off) AS annual_layoffs
FROM layoffs_staging2
GROUP BY YEAR(date)
ORDER BY year DESC;
```
### g. Layoffs by Business Stage

- Examining which business stages are most affected by layoffs:
```sql
SELECT stage, SUM(total_laid_off) AS stage_layoffs
FROM layoffs_staging2
GROUP BY stage
ORDER BY stage_layoffs DESC;
```
### h. Monthly and Cumulative Layoff

- Summarizing and Calculating monthly layoffs:
```sql
SELECT SUBSTRING(date, 1, 7) AS month, SUM(total_laid_off) AS monthly_layoffs
FROM layoffs_staging2
WHERE SUBSTRING(date, 1, 7) IS NOT NULL
GROUP BY month
ORDER BY month ASC;

WITH Rolling_Total AS (
    SELECT 
        SUBSTRING(date, 1, 7) AS month, 
        SUM(total_laid_off) AS total_off
    FROM layoffs_staging2
    WHERE SUBSTRING(date, 1, 7) IS NOT NULL
    GROUP BY month
    ORDER BY month ASC
)
SELECT 
    month, 
    total_off,
    SUM(total_off) OVER (ORDER BY month) AS rolling_total
FROM Rolling_Total;
```
### i. Yearly Layoff Totals by Company

- Break down layoffs per company by year as well as Identify the top 5 companies with the most layoffs each year:
```sql
SELECT 
    company, 
    YEAR(date) AS year, 
    SUM(total_laid_off) AS yearly_layoffs
FROM layoffs_staging2
GROUP BY company, YEAR(date)
ORDER BY yearly_layoffs DESC;


WITH Company_Year AS (
    SELECT 
        company, 
        YEAR(date) AS years, 
        SUM(total_laid_off) AS total_laid_off
    FROM layoffs_staging2
    GROUP BY company, YEAR(date)
), 
Company_Year_Rank AS (
    SELECT 
        *, 
        DENSE_RANK() OVER (PARTITION BY years ORDER BY total_laid_off DESC) AS Ranking
    FROM Company_Year
    WHERE years IS NOT NULL
)
SELECT *
FROM Company_Year_Rank
WHERE Ranking <= 5;
```
