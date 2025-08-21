-- 1. Average handle time by agent
SELECT 
    agent_id, AVG(avg_handle_time_minutes) AS avg_handle_time
FROM
    handle_times
GROUP BY agent_id
ORDER BY avg_handle_time ASC;
	
-- 2. AVG monthly Shrinkage % 
SELECT 
    YEAR(date) AS year,
    MONTH(date) AS month,
    AVG((training + sickness + breaks) * 100) AS avg_monthly_shrinkage
FROM
    shrinkage_factors
GROUP BY YEAR(date) , MONTH(date);

-- 3. Forecast accuracy over time. forecasting the number of customer queries per day

SELECT 
    MONTH(date) AS month, AVG(query_volume) AS daily_average
FROM
    customer_queries
GROUP BY month;

-- It would be beneficial if I had last years data to see how the averages for each month deviate to other months
-- For example, if i say just for this question that the averages made were from 2024 data, I would use the code below to find the forecast accuracy.
SELECT 
    cq.date,
    MONTH(cq.date) AS month,
    query_volume,
    da.daily_average_for_month,
    (ABS(query_volume - daily_average_for_month) / query_volume) * 100 AS mean_absolute_error_percentage
FROM
    customer_queries cq
        JOIN
    (SELECT 
        MONTH(date) AS month,
            AVG(query_volume) AS daily_average_for_month
    FROM
        customer_queries
    GROUP BY month) da ON da.month = MONTH(cq.date);
    
-- Below will find how far on average our forecast is off

SELECT 
    AVG(mean_absolute_error_percentage) AS average_absolute_error
FROM
    (SELECT 
        cq.date,
            MONTH(cq.date) AS month,
            query_volume,
            da.daily_average_for_month,
            (ABS(query_volume - daily_average_for_month) / query_volume) * 100 AS mean_absolute_error_percentage
    FROM
        customer_queries cq
    JOIN (SELECT 
        MONTH(date) AS month,
            AVG(query_volume) AS daily_average_for_month
    FROM
        customer_queries
    GROUP BY month) da ON da.month = MONTH(cq.date)) AS monthly_absolute_errors;
    
    
-- On average, the forecast is off by 6.77%

SELECT 
    DAYNAME(date) AS day_of_the_week,
    AVG(query_volume) AS average_query_volume
FROM
    customer_queries
GROUP BY DAYNAME(date)
ORDER BY AVG(query_volume) DESC;

-- 4. What day has the higest average query volume
SELECT 
    date, AVG(handled_queries) AS daily_average_of_queries
FROM
    handle_times
GROUP BY date;

-- Amount of queries handled by staff each day
-- 5. Which staff works more than the daily average consistently

SELECT 
    date, agent_id, handled_queries
FROM
    handle_times;
    
-- Join both tables together

SELECT 
    da.*, ht.agent_id, ht.handled_queries
FROM
    (SELECT 
        date, AVG(handled_queries) AS daily_average_of_queries
    FROM
        handle_times
    GROUP BY date) da
        RIGHT JOIN
    (SELECT 
        date, agent_id, handled_queries
    FROM
        handle_times) ht ON ht.date = da.date
WHERE
    handled_queries > daily_average_of_queries;

-- The above query creates a table that shows all staff that have worked more than the daily average each day
-- The question asks which staff works more than the daily average consistently

SELECT 
    agent_id,
    COUNT(agent_id) AS staff_working_over_daily_average_consistently
FROM
    (SELECT 
        da.*, ht.agent_id, ht.handled_queries
    FROM
        (SELECT 
        date, AVG(handled_queries) AS daily_average_of_queries
    FROM
        handle_times
    GROUP BY date) da
    RIGHT JOIN (SELECT 
        date, agent_id, handled_queries
    FROM
        handle_times) ht ON ht.date = da.date
    WHERE
        handled_queries > daily_average_of_queries) AS agents_working_more_than_average
GROUP BY agent_id
ORDER BY COUNT(agent_id) DESC;

-- 6. Which days had the highest total shrinkage, and how did query volume perform on those days?
SELECT 
    cq.*,
    (sf.training + sf.sickness + sf.breaks) AS total_shrinkage
FROM
    customer_queries cq
        JOIN
    shrinkage_factors sf ON sf.date = cq.date
ORDER BY (sf.training + sf.sickness + sf.breaks) DESC;
    
    
-- 7. Is there a correlation between shrinkage and average handle time per day?

SELECT 
    sf.date,
    (sf.training + sf.sickness + sf.breaks) AS total_shrinkage,
    AVG(ht.avg_handle_time_minutes) AS average_handle_time
FROM
    shrinkage_factors sf
        JOIN
    handle_times ht ON ht.date = sf.date
GROUP BY sf.date , (sf.training + sf.sickness + sf.breaks)
ORDER BY total_shrinkage DESC;

-- Visualy looking at the table created by the above query, I can see there is not a correlation between total shrinkage and average handle time
-- I will create a line graph when I create a dashboard (either on Power Bi, Looker or Tableau)

-- 8. How much total staff time is scheduled each month, and how much is lost to shrinkage?
WITH scheduled_hours AS(
SELECT
	MONTH(date) as month, YEAR(date) as year, SUM(scheduled_hours) AS total_scheduled_hours
FROM
	staff_schedule
GROUP BY month, year),
monthly_shrinkage AS (
SELECT
	MONTH(date) as month, YEAR(date) AS year, ROUND(SUM((training + sickness + breaks)), 3) AS total_shrinkage
FROM
	shrinkage_factors
GROUP BY
	month, year
)
SELECT
	sh.month, sh.year, sh.total_scheduled_hours, ms.total_shrinkage
FROM
	scheduled_hours sh
		JOIN
	monthly_shrinkage ms ON sh.month = ms.month and sh.year = ms.year;

  



	
