
--Total sales of each product categories--
Select Product as categories, sum(Total_sales) as tot_sales, sum(Operating_profit) as op_profit
From [Adidas US Sales]
Group by Product
Order by sum(Total_sales),sum(Operating_profit)
 

 --Percentage of categories sales over total sales--
with CTE as (Select Product as categories, sum(Total_sales) as tot_cat_sales, sum(Operating_profit) as cat_op_profit
From [Adidas US Sales]
Group by Product
),

CTE2 as (select sum(total_sales) as tot_sales, sum(Operating_profit) as tot_profit
from [Adidas US Sales]
)

Select CTE.categories, (CTE.tot_cat_sales/CTE2.tot_sales)*100 as sales_pct, (CTE.cat_op_profit/CTE2.tot_profit)*100 as pro_pct
From CTE
Cross Join CTE2

--  the percentage of each category's total revenue within each month --
WITH CTE AS (
    SELECT
        YEAR(Invoice_Date) AS year,
        MONTH(Invoice_Date) AS month,
        CONCAT(YEAR(Invoice_Date), '-', MONTH(Invoice_Date)) AS date,
        Product,
        SUM(1.0 * Total_Sales) AS total_revenue
    FROM [dbo].[Adidas US Sales]
    GROUP BY YEAR(Invoice_Date), MONTH(Invoice_Date), Product
),
MonthTotal AS (
    SELECT
        YEAR(Invoice_Date) AS year,
        MONTH(Invoice_Date) AS month,
        CONCAT(YEAR(Invoice_Date), '-', MONTH(Invoice_Date)) AS date,
        SUM(1.0 * Total_Sales) AS total_month_revenue
    FROM [dbo].[Adidas US Sales]
    GROUP BY YEAR(Invoice_Date), MONTH(Invoice_Date)
)
SELECT
    CTE.year,
    CTE.month,
    CTE.date,
    CTE.Product,
    CTE.total_revenue,
    CTE.total_revenue / MonthTotal.total_month_revenue * 100 AS percentage_of_total_sales
FROM
    CTE
JOIN
    MonthTotal ON CTE.year = MonthTotal.year AND CTE.month = MonthTotal.month;


--The revenue of each category IN EACH MONTH--
WITH CTE AS (
    SELECT
        YEAR(Invoice_Date) AS year,
        MONTH(Invoice_Date) AS month,
        CONCAT(YEAR(Invoice_Date), '-', MONTH(Invoice_Date)) AS date,
        Product,
        SUM(1.0 * Total_Sales) AS total_revenue
    FROM [dbo].[Adidas US Sales]
    GROUP BY YEAR(Invoice_Date), MONTH(Invoice_Date), Product
)
SELECT
    year,
    month,
    date,
    SUM(CASE WHEN Product = 'Women''s Athletic Footwear' THEN total_revenue ELSE 0 END) AS Womens_Athletic_Footwear,
    SUM(CASE WHEN Product = 'Women''s Street Footwear' THEN total_revenue ELSE 0 END) AS Womens_Street_Footwear,
    SUM(CASE WHEN Product = 'Women''s Apparel' THEN total_revenue ELSE 0 END) AS Womens_Apparel,
    SUM(CASE WHEN Product = 'Men''s Athletic Footwear' THEN total_revenue ELSE 0 END) AS Mens_Athletic_Footwear,
    SUM(CASE WHEN Product = 'Men''s Street Footwear' THEN total_revenue ELSE 0 END) AS Mens_Street_Footwear,
    SUM(CASE WHEN Product = 'Men''s Apparel' THEN total_revenue ELSE 0 END) AS Mens_Apparel
FROM CTE
GROUP BY year, month, date;


--Comparing revenue of same month versus last year--
with CTE as(
    SELECT 
        YEAR(Invoice_date) AS year 
        ,MONTH(Invoice_date) AS month
        ,CONCAT(YEAR(Invoice_date), '-', MONTH(Invoice_date)) AS date
        ,SUM(Total_Sales) AS tot_revenue 
        ,LAG(CONCAT(YEAR(Invoice_date), '-', MONTH(Invoice_date))) OVER(PARTITION BY MONTH(Invoice_date) ORDER BY YEAR(Invoice_date)) AS month_preyear
        ,LAG(SUM(Total_Sales)) OVER(PARTITION BY MONTH(Invoice_date) ORDER BY YEAR(Invoice_date)) AS amount_month_preyear
    FROM [dbo].[Adidas US Sales] 
    GROUP BY YEAR(Invoice_date), MONTH(Invoice_date)
)

SELECT 
    
    month,year 
    ,tot_revenue
    ,month_preyear 
    ,amount_month_preyear
    ,FORMAT(tot_revenue / amount_month_preyear - 1, 'p') AS pct_diff
FROM CTE
WHERE amount_month_preyear IS NOT NULL