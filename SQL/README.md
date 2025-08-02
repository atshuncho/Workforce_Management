
# Workforce Management SQL Analysis

A collection of SQL queries designed to explore and report on workforce metrics such as handle time, shrinkage, forecast accuracy, and staffing productivity. This project simulates the kind of operational analysis required in a Workforce Management (WFM) function, similar to roles at companies like Monzo.

---

## Tech Stack
- **SQL**
- Sample tables: `handle_times`, `shrinkage_factors`, `customer_queries`, `staff_schedule`
- Dashboards built in: Power BI (compatible with Looker/Tableau)

---

## Key Business Questions & SQL Queries

### 1. Average Handle Time by Agent
```sql
SELECT agent_id, AVG(avg_handle_time_minutes) AS avg_handle_time
FROM handle_times
GROUP BY agent_id
ORDER BY avg_handle_time ASC;
```
Shows how efficiently agents are handling queries.

---

### 2. Average Monthly Shrinkage %
```sql
SELECT 
    YEAR(date) AS year,
    MONTH(date) AS month,
    AVG((training + sickness + breaks) * 100) AS avg_monthly_shrinkage
FROM shrinkage_factors
GROUP BY YEAR(date), MONTH(date);
```
Calculates productivity loss due to training, sickness, and breaks.

---

### 3. Forecast Accuracy Over Time
```sql
SELECT 
    MONTH(date) AS month, AVG(query_volume) AS daily_average
FROM customer_queries
GROUP BY month;
```
Estimates expected daily queries per month to serve as a baseline forecast.

#### Mean Absolute Percentage Error (MAPE)
```sql
SELECT 
    cq.date,
    query_volume,
    da.daily_average_for_month,
    (ABS(query_volume - daily_average_for_month) / query_volume) * 100 AS mean_absolute_error_percentage
FROM customer_queries cq
JOIN (
    SELECT MONTH(date) AS month, AVG(query_volume) AS daily_average_for_month
    FROM customer_queries
    GROUP BY month
) da ON da.month = MONTH(cq.date);
```

#### Overall Forecast Accuracy
```sql
SELECT AVG(mean_absolute_error_percentage) AS average_absolute_error
FROM (
    SELECT 
        cq.date,
        query_volume,
        da.daily_average_for_month,
        (ABS(query_volume - daily_average_for_month) / query_volume) * 100 AS mean_absolute_error_percentage
    FROM customer_queries cq
    JOIN (
        SELECT MONTH(date) AS month, AVG(query_volume) AS daily_average_for_month
        FROM customer_queries
        GROUP BY month
    ) da ON da.month = MONTH(cq.date)
) AS monthly_absolute_errors;
```

*On average, the forecast is off by ~6.77%.*

---

### 4. Query Volume by Day of Week
```sql
SELECT DAYNAME(date) AS day_of_the_week, AVG(query_volume) AS average_query_volume
FROM customer_queries
GROUP BY DAYNAME(date)
ORDER BY average_query_volume DESC;
```
Helps identify staffing needs by weekday. E.g., Wednesday shows highest volume.

---

### 5. Agents Working Above Daily Average
```sql
SELECT agent_id, COUNT(*) AS staff_working_over_daily_average_consistently
FROM (
    SELECT 
        ht.agent_id, ht.handled_queries,
        AVG(ht.handled_queries) OVER (PARTITION BY ht.date) AS daily_avg
    FROM handle_times ht
) sub
WHERE handled_queries > daily_avg
GROUP BY agent_id
ORDER BY COUNT(*) DESC;
```
Ranks agents who consistently handle more queries than the daily average.

---

### 6. Highest Shrinkage Days + Impact on Queries
```sql
SELECT 
    cq.date, query_volume,
    (sf.training + sf.sickness + sf.breaks) AS total_shrinkage
FROM customer_queries cq
JOIN shrinkage_factors sf ON sf.date = cq.date
ORDER BY total_shrinkage DESC;
```

---

### 7. Shrinkage vs. Handle Time Correlation
```sql
SELECT 
    sf.date,
    (sf.training + sf.sickness + sf.breaks) AS total_shrinkage,
    AVG(ht.avg_handle_time_minutes) AS average_handle_time
FROM shrinkage_factors sf
JOIN handle_times ht ON ht.date = sf.date
GROUP BY sf.date, total_shrinkage
ORDER BY total_shrinkage DESC;
```
No strong correlation observed — visual analysis recommended.

---

### 8. Monthly Scheduled Staff Time vs Shrinkage Loss
```sql
SELECT 
    ss.date,
    SUM(ss.scheduled_hours) AS total_staff_time_scheduled,
    (sf.training + sf.sickness + sf.breaks) AS total_shrinkage,
    (SUM(ss.scheduled_hours)) * (sf.training + sf.sickness + sf.breaks) AS staff_lost_to_shrinkage 
FROM staff_schedule ss
JOIN shrinkage_factors sf ON sf.date = ss.date
GROUP BY ss.date, sf.training, sf.sickness, sf.breaks;
```
Quantifies the effect of shrinkage on total scheduled staff hours.

---

