/****** Script for SelectTopNRows command from SSMS  ******/
use [SalesProducts]
Go

-- =========================|| 1-Exploring Data ||=====================
-- ===================================================================
-- show all data
SELECT *
  FROM [dbo].[Sales_products];
 
-- show number of rows in data 
select count(*) from Sales_products ;  -- 186850

-- /////////////////////////////////////////////////////////////////////////////////
-- =========================|| 2-Data Cleaning ||===================== 
-- ================================================================
-- drop missing values
delete from [dbo].[Sales_products]
Where Order_ID is null;

-- Show Duplicates rows
  Select * , Count(*) as duplicate_num
  from [dbo].[Sales_products]
  Group by [Order_ID]
      ,[Product]
      ,[Quantity_ordered]
      ,[Price _each]
      ,[Order_date]
      ,[Purchase_address]
Order by duplicate_num DESC;

-- Remove duplicate Data 
with cte as (

	select * , ROW_NUMBER() over(
		  Partition by [Order_ID],[Product],[Quantity_ordered]
					  ,[Price _each],[Order_date],[Purchase_address] 
		  Order by  [Order_ID],[Product],[Quantity_ordered]
				   ,[Price _each],[Order_date],[Purchase_address]
		  ) AS rn
	FROM [dbo].[Sales_products]
)
delete from cte where rn > 1;

-- Extract column have Month Number						
alter table dbo.Sales_products
add  Month_num smallint;

update dbo.Sales_products
set [Month_num] = MONTH([Order_date]);

-- Extract City from Purchase_address
alter table dbo.Sales_products
Add city varchar(25);

update  dbo.Sales_products
set city = TRIM( SUBSTRING(Purchase_address, 
                CHARINDEX(',' , Purchase_address)+1,
				len(Purchase_address) - CHARINDEX(',' , Purchase_address)-5
				)
			);

-- Add Sales Column for each order to data 
ALTER table dbo.Sales_products
ADD Sales float;

-- Rename column name 
EXEC sp_rename 'dbo.Sales_products.Sales' , 'Total_sales', 'COLUMN';

update dbo.Sales_products
set Total_sales = ROUND( Quantity_ordered * [Price _each], 2 ) ;

-- ADD hour and Minute of Order_date colum that has hour of order 
Alter table dbo.Sales_products
Add Hour_time smallint ,
    Minut_time smallint;

update dbo.Sales_products
set Hour_time = DATEPART(hour, Order_date),
    Minut_time = DATEPART(MINUTE , Order_date);

-- ////////////////////////////////////////////////////////////////////////////////////
-- ==========================|| 3-Data Analysis ||======================
-- =====================================================================

-- Q1: What was the best Year for sales? How much was earned that Year?
------------------------------------------------------------------------
Select YEAR(Order_date) as [year_sale] , Round( SUM(Total_sales),2) as year_sales
from dbo.Sales_products
GROUP BY YEAR(Order_date)
Order by YEAR(Order_date) ;
-- the best year for sale is [2019] with (34456867.65) but
   -- there is regression in sales in [2020] with (8670.29)

-- Q2: What was the best month for sales? How much was earned that month?
-- -------------------------------------------------------------------
Select [Month_num] , Round( SUM(Total_sales),2) as Month_sales
from dbo.Sales_products
GROUP BY [Month_num]
Order by Month_sales DESC ;
-- the best Month for sale is [December] with (4608295.7)

--Q3: What City had the highest number of sales?
-- -------------------------------------------------
Select city , Round(SUM(Total_sales),2) as city_sales
from dbo.Sales_products
group by city
order by city_sales desc;
-- the highest city make sales is [San Francisco, CA] with sales (8254743.55)

-- Q4: What time should we display adverstisement to maximize likelihood of customer's buying product?
-- -----------------------------------------------------------------------------------------
Select Month_num ,Hour_time ,Minut_time, Round(SUM(Total_sales), 2 ) as time_sales
from dbo.Sales_products
group by Month_num, Hour_time, Minut_time
Order by time_sales DESC;
-- the best time should make Advertise is [ Month (4), h(19),  M(20)]

-- Q5: What products are most often sold together?
-- -------------------------------------------------
with order_items as 
(
	select distinct Order_ID,Product 
	from dbo.Sales_products
)
select a.Product , b.Product , Count(*) as frequency
from order_items a
join order_items b
on  a.Order_ID = b.Order_ID
AND a.Product < b.Product
group by  a.Product , b.Product
ORDER BY Count(*) desc
-- the most Products sold togeth are  (iPhone , Lightning Charging Cable) 


-- Q6: What product sold the most? Why do you think it sold the most?
-- -------------------------------------------------------------------
select Product , round(SUM(Quantity_ordered),2) as total_sold
from dbo.Sales_products
group by Product
Order by total_sold Desc

select Product , Round(SUM([Price _each]),2) as total_each_price
from dbo.Sales_products
group by Product
Order by total_each_price Desc;
-- most product sold is [AAA Batteries (4-pack)] because it is the least product price 


