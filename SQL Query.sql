------------------------------------- Step 1 : Creation of database & Display all records -------------------------------------

--1. Create DataBase walmartSales
create database walmartSales

use walmartSales

--2. Import csv data file 

--3. Display all data from table
select * from WalmartData

--4. Rename Tax 5% to VAT


------------------------------------- Step 2 : Data Cleaning -----------------------------

--1. Check null values

select COUNT(*) as 'count_of_non_nulls'
from WalmartData
where not ([Invoice ID] is null and Branch is null and City is null and [Customer type] is null 
	and Gender is null and [Product line] is null and [Unit price] is null and Quantity is null
	and [VAT] is null and Total is null and Date is null and Time is null and Payment is null
	and cogs is null and [gross margin percentage] is null and [gross income] is null and Rating is null)

	-- No null values

--2. Check duplicates based on Invoice ID

select [Invoice ID], COUNT(*) as 'count_of_duplicates'
from WalmartData
group by [Invoice ID]
having COUNT([Invoice ID]) > 1

	-- No duplicates


------------------------------------- Step 3 : Feature Engineering -----------------------------

--1. Add new column time_of_day

alter table walmartData
add time_of_day varchar(30)

update WalmartData
set time_of_day = (
	case 
		when Time between '00:00:00' and '12:00:00' then 'Morning'
		when Time between '12:01:00' and '16:00:00' then 'Afternoon'
		else 'Evening'
	end
)

--2. Add new column day_name

alter table walmartData
add date_name varchar(30)

update WalmartData
set date_name = datename(DW, Date)


--3. Add new column month_name

alter table walmartData
add month_name varchar(30)

update WalmartData
set month_name = datename(m,date) 


------------------------------------- Step 3 : EDA -----------------------------

--------------------------------------------------------------------------------
				-- Generic Questions 
--------------------------------------------------------------------------------

-- 1. How many distinct cities are present in the dataset?
		
select distinct(City) as 'Unique Cities'
from WalmartData


-- 2. In which city is each branch situated?

select distinct(city), Branch
from WalmartData
		


--------------------------------------------------------------------------------
				-- Product Analysis
--------------------------------------------------------------------------------

-- 1. How many distinct product lines are there in the dataset?

select count(distinct([Product line])) as 'Unique Product Lines'
from WalmartData
	

-- 2. What is the most common payment method?

with payment_mode as
(
	select Payment, COUNT(payment) as 'count_of_payment_mode'
	from WalmartData
	group by Payment
)
select Payment
from payment_mode
where count_of_payment_mode = ( select MAX(count_of_payment_mode) from payment_mode)


-- 3. What is the most selling product line?

with most_sold_product as
(
	select [Product line], SUM(cast(quantity as int)) as 'Total_Quantity_Sold'
	from WalmartData
	group by [Product line]
)
select [Product line]
from most_sold_product
where Total_Quantity_Sold = (select MAX(Total_Quantity_Sold) from most_sold_product)


-- 4. What is the total revenue by month?

select month_name, SUM(cast(total as float)) as 'Total_Revenue'
from WalmartData
group by month_name
order by Total_Revenue desc


-- 5. Which month recorded the highest Cost of Goods Sold (COGS)?

with  highest_cogs_month as
(
	select month_name, sum(cast(cogs as float)) as 'Highest_COGS'
	from WalmartData
	group by month_name
)
select month_name
from highest_cogs_month
where highest_cogs = (select MAX(highest_cogs) from highest_cogs_month)


-- 6. Which product line generated the highest revenue?

select [Product line], Highest_Revenue
from (
	select [Product line], 
	SUM(CAST(total as float)) as Highest_Revenue,
	ROW_NUMBER() over(order by SUM(cast(total as float)) desc) as rnk
	from WalmartData
	group by [Product line]
)q
where q.rnk = 1


-- 7. Which city has the highest revenue?

select City, Highest_Revenue
from(
	select City, SUM(cast(total as float)) as 'Highest_Revenue',
	ROW_NUMBER() over(order by SUM(cast(total as float)) desc) as rnk
	from WalmartData
	group by City
)q
where q.rnk = 1


-- 8. Which product line incurred the highest VAT?

select [Product line], Highest_VAT
from(
	select [Product line], SUM(cast(Vat as float)) as 'Highest_VAT',
	ROW_NUMBER() over(order by  SUM(cast(Vat as float)) desc) rnk
	from WalmartData
	group by [product line]
)q
where q.rnk = 1


-- 9. Retrieve each product line and add a column product_category, 
		-- indicating 'Good' or 'Bad,' based on whether its sales are above the average.

alter table walmartData
add Product_Category varchar(30)

update WalmartData
set Product_Category = (
	case 
		when total >= (select avg(cast(total as float)) from WalmartData) then 'Good'
		else 'Bad'
	end 
)
from WalmartData
	
	
-- 10. Which branch sold more products than average product sold?

select Branch, SUM(cast(quantity as int))as 'Qty'
from WalmartData
group by Branch
having SUM(cast(quantity as int)) > AVG(CAST(quantity as int))


-- 11. What is the most common product line by gender?

select Gender, [Product line]
from (
	select gender,[Product line], count([Product line])  as 'cnt_product',
	ROW_NUMBER() over(partition by gender order by count([Product line]) desc) as rnk
	from WalmartData
	group by Gender, [Product line]
)q
where q.rnk = 1


-- 12. What is the average rating of each product line?

select [Product line], round(AVG(cast(rating as float)),2) as 'Avg_Rating'
from WalmartData
group by [Product line]
order by Avg_Rating



--------------------------------------------------------------------------------
				-- Customer Analysis
--------------------------------------------------------------------------------

-- 1. How many unique customer types does the data have?

select distinct([Customer type]) 'Unique Customer Type'
from WalmartData


-- 2. How many unique payment methods does the data have?

select distinct(Payment) 'Unique Payment Mode'
from WalmartData


-- 3. Which is the most common customer type?

with common_cust_type as
(
	select [Customer type], COUNT([Customer type]) as 'count_of_cust_type' 
	from WalmartData
	group by [Customer type]
)
select [Customer type] 
from common_cust_type
where count_of_cust_type = (select MAX(count_of_cust_type) from common_cust_type)


-- 4. Which customer type buys the most? or Identify the customer type that generates the highest revenue.

select Top 1 [Customer type], SUM(cast(total as float)) as 'Total',
ROW_NUMBER() over(order by SUM(cast(total as float)) desc) as rnk
from WalmartData
group by [Customer type]


-- 5. What is the gender of most of the customers?

select top 1 Gender
from WalmartData
group by Gender
order by COUNT(gender) desc


-- 6. What is the gender distribution per branch?

select Branch, Gender, COUNT(gender) 'cnt_gender'
from WalmartData
group by Branch, Gender
order by branch, cnt_gender desc


-- 7. Which time of the day do customers give most ratings?

select Top 1 time_of_day, COUNT(cast(Rating as float)) as 'Total_ratings'
from WalmartData
group by time_of_day
order by Total_ratings desc


-- 8. Which time of the day do customers give most ratings per branch?

select Branch, time_of_day, Total_ratings
from(
	select time_of_day, Branch, COUNT(cast(Rating as float)) as 'Total_ratings',
	ROW_NUMBER() over(partition by branch order by COUNT(cast(Rating as float)) desc) as rnk
	from WalmartData
	group by time_of_day, Branch
)q
where q.rnk = 1


-- 9. Which day of the week has the best avg ratings?

select Top 1 date_name, round(AVG(cast(rating as float)),2) as 'Avg_rating'
from WalmartData
group by date_name
order by Avg_rating desc


-- 10. Which day of the week has the best average ratings per branch?

select Branch, time_of_day, Avg_Rating
from(
	select Branch, time_of_day, ROUND(avg(cast(rating as float)),2) as 'Avg_Rating',
	ROW_NUMBER() over(partition by branch order by ROUND(avg(cast(rating as float)),2)) rnk
	from WalmartData
	group by Branch, time_of_day
)q
where q.rnk = 1



--------------------------------------------------------------------------------
				-- Sales Analysis
--------------------------------------------------------------------------------

-- 1. Number of sales made in each time of the day per weekday

select date_name, time_of_day, COUNT(*) as 'Total_sales'
from WalmartData
group by date_name, time_of_day
having date_name not in ('Saturday', 'Sunday')
order by Total_sales desc


-- 2. Which city has the largest tax percent/ VAT (Value Added Tax)?

select Top 1 City, SUM(cast(vat as float)) as 'Total_Vat'
from WalmartData
group by city
order by Total_Vat desc


-- 3. Which customer type pays the most VAT?

select Top 1 [Customer type], SUM(cast(vat as float)) as 'Total_Vat'
from WalmartData
group by [Customer type]
order by Total_Vat desc
