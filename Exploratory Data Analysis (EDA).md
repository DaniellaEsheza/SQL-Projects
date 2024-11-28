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
