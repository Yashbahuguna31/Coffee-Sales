
-- checking the info of the table 
select column_name, data_type, is_nullable, column_default
from information_schema.columns
where table_name = 'coffee_sales'

-- TOTAL SALES
select round(sum(transaction_qty*unit_price),2) as total_sales
from coffee_sales

-- TOTAL SALES KPI - MOM DIFFERENCE AND MOM GROWTH

with cte as (
	     select to_char(transaction_date,'Mon') as months,extract(month from transaction_date ) as month_number
		    ,round(sum(transaction_qty*unit_price),2) as sales
	     from coffee_sales
	     group by to_char(transaction_date,'Mon'),extract(month from transaction_date )
	    order by month_number asc
	        )
select months,sales,prv_month_sales,
       (sales - prv_month_sales) as diff_sales,
	   round(((sales - prv_month_sales)/prv_month_sales)*100,2) as percentage_change
from (
      select *,
             lag(sales) over(order by month_number asc) prv_month_sales
       from cte
	 ) x
	 
-- TOTAL ORDERS

select count(transaction_qty) as orders
from coffee_sales

-- TOTAL ORDERS KPI - MOM DIFFERENCE AND MOM GROWTH

with cte as (
	      select to_char(transaction_date,'Mon') as months,extract(month from transaction_date ) as month_number
		     ,count(transaction_qty) as orders
	      from coffee_sales
	      group by to_char(transaction_date,'Mon'),extract(month from transaction_date )
	      order by month_number asc
	        )
select months,orders,prv_month_orders,
       (orders - prv_month_orders) as diff_orders,
	   round((orders - prv_month_orders)*100.0/prv_month_orders,2) as percentage_change
from (
	select *,
             lag(orders) over(order by month_number asc) prv_month_orders
       from cte
	 ) x

-- TOTAL QUANTITY SOLD

select sum(transaction_qty) as quantity
from coffee_sales

-- TOTAL QUANTITY SOLD KPI - MOM DIFFERENCE AND MOM GROWTH

with cte as (
	      select to_char(transaction_date,'Mon') as months,extract(month from transaction_date ) as month_number
		     ,sum(transaction_qty) as quantity
	      from coffee_sales
	      group by to_char(transaction_date,'Mon'),extract(month from transaction_date )
	      order by month_number asc
	        )
select months,quantity,prv_month_quantity,
       (quantity - prv_month_quantity) as diff_quantity,
	   round((quantity - prv_month_quantity)*100.0/prv_month_quantity,2) as percentage_change
from (
	select *,
             lag(quantity) over(order by month_number asc) prv_month_quantity
       from cte
	 ) x
	 
-- CALENDAR TABLE – DAILY SALES, QUANTITY and TOTAL ORDERS

select transaction_date, 
       round(sum(transaction_qty*unit_price),2) as sales,
	   count(transaction_qty) as orders,
	   sum(transaction_qty) as quantity
from coffee_sales
group by transaction_date
order by transaction_date

-- COMPARISION OF AVERAGE SALES PER MONTH OVER PERIOD

with cte as(
	     select transaction_date, 
		     round(sum(transaction_qty*unit_price),2) as sales,
		     count(transaction_qty) as orders,
		     sum(transaction_qty) as quantity
	     from coffee_sales
	     group by transaction_date
	     order by transaction_date
	     )
select *,
       round(avg(avg_sales) over(),2) as overall_avg
from (
	select to_char(transaction_date,'Mon') as month,
		extract(month from transaction_date) as month_number, 
		round(avg(sales),2) as avg_sales
	from cte
	group by to_char(transaction_date,'Mon'),extract(month from transaction_date)
	order by month_number
	 ) x

-- SALES BY WEEKDAY / WEEKEND OVER MONTHS

select * from coffee_sales

with cte as (
	      select to_char(transaction_date,'Mon') as month,
		     extract(month from transaction_date) as month_number,
		     extract(DOW from transaction_date) as day_week_number,
		     transaction_qty, unit_price
	      from coffee_sales
	        )
select month,weekday,weekend
from (
		select month,month_number,
			   sum(case when day_type = 'weekday' then sales else 0 end) as weekday,
			   sum(case when day_type = 'weekend' then sales else 0 end) as weekend
		from (
				select month,day_type,month_number,
					   sum(sales) as sales
				from (
						select  month,month_number,round((transaction_qty*unit_price),2) as sales,
								case 
									when day_week_number in (0,6) then 'weekend'
									else 'weekday'
								 end as day_type
						from cte
					  ) subquery
				group by month,day_type,month_number
				order by sales desc
			 ) sub
		group by month,month_number
		order by month_number asc
	) main

-- SALES BY STORE LOCATION

select store_location,
       round(sum(transaction_qty*unit_price),2) as sales
from coffee_sales
group by store_location
order by sales desc

-- SALES BY PRODUCT CATEGORY

select product_category,
       round(sum(transaction_qty*unit_price),2) as sales
from coffee_sales
group by product_category
order by sales desc

-- SALES BY TOP PRODUCT TYPE PER PRODUCT CATEGORY
select * from coffee_sales

with cte as (
				select product_category,product_type,
					   round(sum(transaction_qty*unit_price),2) as sales
				from coffee_sales
				group by product_category,product_type,store_location
				order by sales desc
            )
select product_category,product_type,sales
from (
		select product_category,product_type,sales,
			   dense_rank() over(partition by product_category order by sales desc) rnk
		from cte
	  ) subquery
where rnk = 1

