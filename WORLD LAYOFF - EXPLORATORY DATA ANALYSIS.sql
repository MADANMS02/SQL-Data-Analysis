-- EXPLORATORY DATA ANALUSIS
select *
from layoff_staging2
;

-- FIND WHICH COMPANY HAS MORE LAYOFF

select * 
FROM layoff_staging2
order by total_laid_off DESC
;

SELECT COMPANY,SUM(TOTAL_LAID_OFF) AS LAIDOFF
FROM layoff_staging2
GROUP BY COMPANY 
ORDER BY LAIDOFF DESC
LIMIT 5
;

-- WHICH COMPANY HAS HIGHER FUNDS
SELECT *
FROM layoff_staging2
ORDER BY funds_raised_millions DESC
;

SELECT COMPANY,SUM(FUNDS_RAISED_MILLIONS)
FROM layoff_staging2
GROUP BY COMPANY
ORDER BY SUM(FUNDS_RAISED_MILLIONS) DESC
LIMIT 5;

-- WHICH COMPANY SHUTDOWN AND HAD MORE FUNDS

SELECT *
from layoff_staging2
WHERE percentage_laid_off=1
ORDER BY funds_raised_millions DESC
;

SELECT world_layoffs.layoff_staging2.company,SUM(world_layoffs.layoff_staging2.funds_raised_millions) AS FUNDS
FROM world_layoffs.layoff_staging2
WHERE percentage_laid_off=1
GROUP BY company
ORDER BY funds DESC
;

-- IN WHICH CUNTRY THERE MORE LAYOFFS

SELECT COUNTRY,SUM(world_layoffs.layoff_staging2.total_laid_off) AS LAYOFFS
FROM layoff_staging2
GROUP BY COUNTRY
ORDER BY LAYOFFS DESC
LIMIT 5
;

-- IN WHICH CITY THERE MORE LAYOFFS
SELECT LOCATION,SUM(world_layoffs.layoff_staging2.total_laid_off) AS LAYOFFS
FROM layoff_staging2
GROUP BY LOCATION
ORDER BY LAYOFFS DESC
LIMIT 5
;

-- IN WHICH INDUSTRY THERE MORE LAYOFFS
SELECT industry,SUM(world_layoffs.layoff_staging2.total_laid_off) AS LAYOFFS
FROM layoff_staging2
GROUP BY industry
ORDER BY LAYOFFS DESC
LIMIT 5
;

-- DATE RANGE OF LAY OFF
SELECT MIN(`DATE`),MAX(`DATE`)
FROM layoff_staging2
;

-- THE YEAR WHERE THE LAY OFF IS MORE

SELECT YEAR(`DATE`) AS `YEAR`,SUM(world_layoffs.layoff_staging2.total_laid_off) AS LAYOFFS
FROM layoff_staging2
GROUP BY `YEAR`
ORDER BY LAYOFFS DESC
LIMIT 5
;

-- THE MONTH WHERE THE LAY OFF IS MORE
SELECT MONTH(`DATE`) AS `MONTH`,SUM(world_layoffs.layoff_staging2.total_laid_off) AS LAYOFFS
FROM layoff_staging2
GROUP BY `MONTH`
ORDER BY LAYOFFS DESC
LIMIT 5
;

SELECT substring(`DATE`,1,7)AS `MONTH` ,SUM(world_layoffs.layoff_staging2.total_laid_off) AS LAYOFFS
FROM layoff_staging2
GROUP BY `MONTH`
ORDER BY LAYOFFS DESC
LIMIT 5
;

-- LAYOFF ROLIING DATA PER YEAR

WITH LAYOFF 
AS
(
SELECT substring(`DATE`,1,7) AS `MONTH`,SUM(world_layoffs.layoff_staging2.total_laid_off) AS LAYOFFS
FROM layoff_staging2
WHERE substring(`DATE`,1,7) IS NOT NULL
GROUP BY substring(`DATE`,1,7)
)
SELECT 
L.`MONTH`,
LAYOFFS,
SUM(L.LAYOFFS) OVER(ORDER BY L.`MONTH`) AS LAYOFF_ROLL
FROM LAYOFF L
;

-- LAYOFF ROLIING DATA PER MONTH
WITH LAYOFF
AS
(
SELECT DATE_FORMAT(`DATE`,'%Y-%M')AS `MONTH`,SUM(TOTAL_LAID_OFF) AS LAIDO
FROM layoff_staging2
WHERE  DATE_FORMAT(`DATE`,'%Y-%M') IS NOT NULL
group by  DATE_FORMAT(`DATE`,'%Y-%M')
)
select *,
SUM(LAIDO) OVER (ORDER BY `MONTH`)
FROM LAYOFF
;


-- TOP COMPANY LAYOFFS PER YEAR

SELECT COMPANY,YEAR(`DATE`),SUM(TOTAL_LAID_OFF)
FROM layoff_staging2
GROUP BY COMPANY,YEAR(`DATE`)
HAVING SUM(TOTAL_LAID_OFF) IS NOT NULL
ORDER BY COMPANY DESC
;

WITH LAYOFF(COMPANY,YEARS,TLAY)
AS
(
SELECT COMPANY,YEAR(`DATE`),SUM(TOTAL_LAID_OFF)
FROM layoff_staging2
GROUP BY COMPANY,YEAR(`DATE`)
),
COMPANY_RANK
AS
(
SELECT *,
dense_rank() OVER(partition by YEARS ORDER BY TLAY DESC)AS CRANK
from LAYOFF
WHERE YEARS IS NOT NULL
)
SELECT *
FROM COMPANY_RANK
WHERE CRANK<=5
;

-- TOP 10 COMPANIES AVG LAY OFF
SELECT COMPANY,AVG(TOTAL_LAID_OFF)
FROM layoff_staging2
GROUP BY COMPANY
ORDER BY AVG(TOTAL_LAID_OFF) DESC
LIMIT 10
;

-- TOP 3 COMPANIES WITH HIGHEST LAY OFF EACH YEAR
WITH LAYOFF
AS
(
SELECT COMPANY,YEAR(`DATE`)AS YEARS,SUM(TOTAL_LAID_OFF) AS S_LAY
FROM layoff_staging2
group by COMPANY,YEARS
),
CRANK
AS
(
SELECT * ,DENSE_RANK() OVER(PARTITION BY YEARS ORDER BY S_LAY DESC) AS CORANK
FROM LAYOFF
WHERE YEARS IS NOT NULL AND S_LAY IS NOT NULL
)
SELECT * 
FROM CRANK
WHERE CORANK<=3
;

-- For every company, calculate the change in layoffs compared to its previous layoff event
with layoff
as(
SELECT COMPANY,`DATE`,SUM(TOTAL_LAID_OFF) AS S_LAY
FROM layoff_staging2
group by COMPANY,`DATE`
)
select * ,
lag(S_LAY) over(partition by company order by `date`) as previous_layoff
from layoff
where s_lay is not null 
;

/**
-- For each year, show:Total layoffs
Number of companies that had layoffs
Average layoffs per company
Company with the highest layoffs that year
**/

WITH layoff AS
(
    SELECT
        YEAR(`date`) AS years,
        SUM(total_laid_off) AS sums,
        COUNT(DISTINCT company) AS companies,
        SUM(total_laid_off) / COUNT(DISTINCT company) AS avg_company
    FROM layoff_staging2
    WHERE YEAR(`date`) IS NOT NULL
    GROUP BY YEAR(`date`)
),

layoff2 AS
(
    SELECT
        company,
        YEAR(`date`) AS years,
        SUM(total_laid_off) AS company_layoffs,
        DENSE_RANK() OVER
        (
            PARTITION BY YEAR(`date`)
            ORDER BY SUM(total_laid_off) DESC
        ) AS crank
    FROM layoff_staging2
    WHERE YEAR(`date`) IS NOT NULL
    GROUP BY company, YEAR(`date`)
)

SELECT
    l1.years,
    l1.sums AS total_laid_off,
    l1.companies,
    l1.avg_company,
    l2.company AS top_company,
    l2.company_layoffs
FROM layoff l1
JOIN layoff2 l2
    ON l1.years = l2.years
WHERE l2.crank = 1
ORDER BY l1.years;