use gdb023;
select * from fact_gross_price;
select * from fact_manufacturing_cost;
select * from fact_sales_monthly;


-- 1. Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.

select market
from dim_customer
where customer = 'Atliq Exclusive' and region = 'APAC'
group by market;

-- 2. What is the percentage of unique product increase in 2021 vs. 2020? The final output contains these fields,
-- unique_products_2020 ,unique_products_2021,percentage_chg

create temporary table unique_products as 
select 
(select count(distinct product_code)
from fact_sales_monthly 
where fiscal_year='2020') as unique_products_2020,
(select count(distinct product_code)
from fact_sales_monthly
where fiscal_year='2021') as unique_products_2021 ;


select unique_products_2020,unique_products_2021,
round((unique_products_2021-unique_products_2020)*100/unique_products_2020,2)as percentage_change
from unique_products;

-- 3. Provide a report with all the unique product counts for each segment and sort them in descending order of 
-- product counts. The final output contains 2 fields, segment & product_count

select segment, count(distinct product_code) as product_count
from dim_product
group by segment
order by product_count desc;

-- 4. Follow-up: Which segment had the most increase in unique products in 2021 vs 2020? The final output 
-- contains these fields: segment, product_count_2020 , product_count_2021 , difference

create temporary table product_2020 as 
(select p.segment, count(distinct m.product_code)as product_count_2020
from fact_sales_monthly as m 
left join dim_product as p 
on p.product_code=m.product_code
where m.fiscal_year='2020'
group by segment ) ;

create temporary table product_2021 as 
(select p.segment, count(distinct m.product_code)as product_count_2021
from fact_sales_monthly as m 
left join dim_product as p 
on p.product_code=m.product_code
where m.fiscal_year='2021'
group by segment ) ;

select p20.segment , p20.product_count_2020 , p21.product_count_2021 ,
 max(abs(p21.product_count_2021 - p20.product_count_2020)) as  difference
from product_2020 as p20
inner join product_2021 as p21 
on p20.segment = p21.segment
group by p20.segment , p20.product_count_2020, p21.product_count_2021
order by difference desc 
limit 1 ;

-- 5.Get the products that have the highest and lowest manufacturing costs. The final output should contain 
-- these fields:  product_code, product ,manufacturing_cost

(
select m.product_code , p.product , max(m.manufacturing_cost) as manufacturing_cost
from dim_product as p 
inner join fact_manufacturing_cost as m 
on m.product_code=p.product_code 
group by m.product_code , p.product 
order by manufacturing_cost desc 
limit 1  
)
union 
(
select m.product_code , p.product , min(m.manufacturing_cost) as manufacturing_cost
from dim_product as p 
inner join fact_manufacturing_cost as m 
on m.product_code=p.product_code 
group by m.product_code , p.product 
order by manufacturing_cost 
limit 1 
);

-- 6. Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct 
-- for the fiscal year 2021 and in the Indian market. The final output contains these fields:
-- customer_code , customer , average_discount_percentage

select f.customer_code , c.customer , round(avg(f.pre_invoice_discount_pct),2) as average_discount_percentage
from dim_customer as c
inner join fact_pre_invoice_deductions as f
on f.customer_code = c.customer_code
where f.fiscal_year='2021' and c.market='India'
group by f.customer_code , c.customer
order by average_discount_percentage desc 
limit 5 ;

-- 7. Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month. 
-- This analysis helps to get an idea of low and high-performing months and take strategic decisions.
-- The final report contains these columns: Month , Year , Gross sales Amount

select monthname(m.date) as month , year(m.date) as year , 
sum(m.sold_quantity*p.gross_price) / 2 as gross_sales_amount
from fact_sales_monthly as m
left join fact_gross_price as p
on p.product_code = m.product_code
left join dim_customer as c
on c.customer_code = m.customer_code
where c.customer='Atliq Exclusive'
group by month , year , month(date)
order by year, month(date) ;

-- 8. In which quarter of 2020, got the maximum total_sold_quantity? The final output contains these fields 
-- sorted by the total_sold_quantity, Quarter , total_sold_quantity

select quarter(date) as Quarter , sum(sold_quantity) as total_sold_quantity
from fact_sales_monthly 
where fiscal_year='2020'
group by Quarter
order by total_sold_quantity desc
limit 1 ;

-- 9. Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of 
-- contribution? The final output contains these fields:  channel, gross_sales_mln , percentage;

With   sales_summary(
select c.channel as channel , 
sum(s.sold_quantity*p.gross_price) as gross_sales_min,
rank() over(order by sum(s.sold_quantity*p.gross_price) desc) as rank
from fact_sales_monthly as s
left join fact_gross_price as p
on p.product_code = s.product_code
left join dim_customer as c
on c.customer_code = s.customer_code 
where s.fiscal_year='2021'
group by c.channel 
)
select channel, gross_sales_min ,
round(gross_sales_min)*100/(select sum(gross_sales_min) from sales_summary),1 ) as percentage
from sales_summary 
where rank = 1 
group by gross_sales_min;

-- 10. Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? 
-- The final output contains these fields: division ,product_code, product, total_sold_quantity, rank_order

with rank_summary  as (
select p.division , p.product_code,p.product , sum(s.sold_quantity) as total_sold_quantity,
row_number() over (partition by p.division order by sum(s.sold_quantity) desc) as rank_order
from fact_sales_monthly as s 
left join dim_product as p 
on p.product_code = s.product_code
where s.fiscal_year = '2021'
group by p.division , p.product_code , p.product
)
select division , product_code, product, total_sold_quantity, rank_order
from rank_summary 
where rank_order < 4 ;






































