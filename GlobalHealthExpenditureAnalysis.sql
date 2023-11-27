--Growth rate of gov spending on health out of total gov spending over years--
with CTE as (Select income, year, (current_health_expenditure/general_government_expenditure) as CHE_GGE,  Rank() OVER (Partition by year order by current_health_expenditure/general_government_expenditure) as row_no
From GHED_data
Where general_government_expenditure is not null and general_government_expenditure <>0)

Select CTE.year, CTE.income, sum(CTE.CHE_GGE) as CHE_GGE_Growth
From CTE
Group by  income, year
Order by income, year





