--A. Sales performance analysis--

--- Total sales revenue--
with cte as (Select Sales*Quantity as tot_sales
From [E-commerce records 2020])

select sum(tot_sales) as total_revenue
from cte

-- Profit trends over time (monthly)--
	Select MONTH(Order_Date) as month, sum(Profit) as monthly_profit
From [E-commerce records 2020]
Group by MONTH(Order_Date)
Order by MONTH(Order_Date)

-- Sales revenue by product category and sub-category--
with cte as (Select Category, Sub_category, (Sales*Quantity) as tot_sales, profit
From [E-commerce records 2020])

select Category, Sub_category, sum(tot_sales) as total_revenue, sum(profit) as tot_profit
from cte
Group by Category, Sub_category
Order by Category, Sub_category


--- Distribution of sales across different regions, states, and cities--
Select Country, State, City, sum(profit)as tot_profit, count(Order_ID) as ord_amount
From [E-commerce records 2020]
Group by City, State ,Country


--1. The retention rate of the company in each month in 2020--

WITH CTE AS 
	(SELECT customer_id  
        ,MIN(MONTH(Order_Date)) AS first_month_tran 
    FROM [E-commerce records 2020] 
    GROUP BY customer_id 
), 

CTE2 AS 
	(SELECT first_month_tran 
        ,COUNT(DISTINCT customer_id) AS new_customers
    FROM CTE 
    GROUP BY first_month_tran
), 

CTE3 AS 
	(SELECT customer_id 
        ,MONTH(Order_Date) AS subsequent_month
    FROM [E-commerce records 2020] AS tran20
    GROUP BY customer_id, MONTH(Order_Date)), 

CTE4 AS 
	(SELECT first_month_tran 
        ,subsequent_month 
        ,COUNT(CTE.customer_id) AS retained_customers
        ,FIRST_VALUE(COUNT(DISTINCT CTE.customer_id)) OVER(PARTITION BY first_month_tran ORDER BY first_month_tran, subsequent_month) AS original_customers
    FROM CTE3 
    JOIN CTE 
        ON CTE3.customer_id = CTE.customer_id 
    GROUP BY first_month_tran, subsequent_month), 

CTE5 AS 
	(SELECT first_month_tran
			,subsequent_month - first_month_tran AS subsequent_month
			,retained_customers
			,original_customers
			,FORMAT(1.0*retained_customers / original_customers, 'p') AS retention_rate
		FROM CTE4)
	
SELECT first_month_tran ,original_customers
    ,FORMAT(SUM(CASE WHEN subsequent_month = 0 THEN retained_customers ELSE 0 END) / original_customers, 'p') AS [0]
    ,FORMAT(1.0*SUM(CASE WHEN subsequent_month = 1 THEN retained_customers ELSE 0 END) / original_customers, 'p') AS [1]
    ,FORMAT(1.0*SUM(CASE WHEN subsequent_month = 2 THEN retained_customers ELSE 0 END) / original_customers, 'p') AS [2]
    ,FORMAT(1.0*SUM(CASE WHEN subsequent_month = 3 THEN retained_customers ELSE 0 END) / original_customers, 'p') AS [3]
    ,FORMAT(1.0*SUM(CASE WHEN subsequent_month = 4 THEN retained_customers ELSE 0 END) / original_customers, 'p') AS [4]
    ,FORMAT(1.0*SUM(CASE WHEN subsequent_month = 5 THEN retained_customers ELSE 0 END) / original_customers, 'p') AS [5]
    ,FORMAT(1.0*SUM(CASE WHEN subsequent_month = 6 THEN retained_customers ELSE 0 END) / original_customers, 'p') AS [6]
    ,FORMAT(1.0*SUM(CASE WHEN subsequent_month = 7 THEN retained_customers ELSE 0 END) / original_customers, 'p') AS [7]
    ,FORMAT(1.0*SUM(CASE WHEN subsequent_month = 8 THEN retained_customers ELSE 0 END) / original_customers, 'p') AS [8]
    ,FORMAT(1.0*SUM(CASE WHEN subsequent_month = 9 THEN retained_customers ELSE 0 END) / original_customers, 'p') AS [9]
    ,FORMAT(1.0*SUM(CASE WHEN subsequent_month = 10 THEN retained_customers ELSE 0 END) / original_customers, 'p') AS [10]
    ,FORMAT(1.0*SUM(CASE WHEN subsequent_month = 11 THEN retained_customers ELSE 0 END) / original_customers, 'p') AS [11]
FROM CTE5
GROUP BY first_month_tran, original_customers
ORDER BY first_month_tran


--RFM analysis--

Select *
From [E-commerce records 2020]
Where Quantity <0

WITH CTE AS (
    SELECT 
        *,
        ROW_NUMBER() OVER(PARTITION BY Order_ID, Product_ID, Quantity, Order_Date ORDER BY Order_Date ) AS dup_check
    FROM [E-commerce records 2020]
),
CTE1 AS (
    SELECT 
        Order_ID,
        Product_ID,
        Quantity,
        Order_Date,
        Customer_ID, Sales,
        Country
    FROM CTE
    WHERE Quantity > 0 
        AND Customer_ID IS NOT NULL 
        AND dup_check = 1
),

	CTE2 as (SELECT Customer_ID, 
			MAX(Order_Date) AS last_active_date, 
			DATEDIFF(day, MAX(Order_Date), '2020-12-31') AS Recency,
			COUNT(DISTINCT(Order_ID)) AS Frequency,
			sum(Sales) AS Monetary
	FROM CTE1
	GROUP BY Customer_ID),
CTE3 as
(SELECT Customer_ID,
			last_active_date,
			Recency,
			Frequency,
			Monetary,
			ROUND(PERCENT_RANK() OVER(ORDER BY Recency) * 100, 2) AS pctile_recency,
			ROUND(PERCENT_RANK() OVER(ORDER BY Frequency) * 100, 2) AS pctile_frequency,
			ROUND(PERCENT_RANK() OVER(ORDER BY Monetary) * 100, 2) AS pctile_monetary
	FROM CTE2),

CTE4 as 
	(SELECT Customer_ID,
			last_active_date,
			Recency,
			Frequency,
			Monetary,
			pctile_recency,
			pctile_frequency,
			pctile_monetary,
			CASE WHEN pctile_recency >= 0 AND pctile_recency <= 25 THEN 4
				 WHEN pctile_recency > 25 AND pctile_recency <= 50 THEN 3
				 WHEN pctile_recency > 50 AND pctile_recency <= 75 THEN 2
				 WHEN pctile_recency > 75 THEN 1
			END AS Recency_rank,
			CASE WHEN pctile_frequency >= 0 AND pctile_frequency <= 25 THEN 1
				 WHEN pctile_frequency > 25 AND pctile_frequency <= 50 THEN 2
				 WHEN pctile_frequency > 50 AND pctile_frequency <= 75 THEN 3
				 WHEN pctile_frequency > 75 THEN 4
			END AS Frequency_rank,
			CASE WHEN pctile_monetary >= 0 AND pctile_monetary <= 25 THEN 1
				 WHEN pctile_monetary > 25 AND pctile_monetary <= 50 THEN 2
				 WHEN pctile_monetary > 50 AND pctile_monetary <= 75 THEN 3
				 WHEN pctile_monetary > 75 THEN 4
			END AS Monetary_rank
	FROM CTE3),

CTE5 AS --calculate sum of Recency_rank, Frequency_rank and Monetary_rank then calculate the quantile of RFM
(SELECT		Customer_ID,
			last_active_date,
			Recency,
			Frequency,
			Monetary,
			Recency_rank,
			Frequency_rank,
			Monetary_rank,
			Recency_rank + Frequency_rank + Monetary_rank AS RFM_score,
			ROUND(PERCENT_RANK() OVER(ORDER BY Recency_rank + Frequency_rank + Monetary_rank) * 100, 2) AS pctile_RFM
	FROM CTE4
)
	SELECT --label the level
			Customer_ID,
			last_active_date,
			Recency,
			Frequency,
			Monetary,
			Recency_rank,
			Frequency_rank,
			Monetary_rank,
			CASE WHEN pctile_RFM >= 0 AND pctile_RFM <= 25 THEN 'Extremely Low'
				 WHEN pctile_RFM > 25 AND pctile_RFM <= 50 THEN 'Low'
				 WHEN pctile_RFM > 50 AND pctile_RFM <= 75 THEN 'Normal'
				 WHEN pctile_RFM > 75 THEN 'VIP'
			END AS RFM_level
	FROM CTE5
