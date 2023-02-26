# Q1
-- Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region

SELECT DISTINCT(MARKET)  FROM DIM_CUSTOMER 
WHERE CUSTOMER = 'ATLIQ EXCLUSIVE' AND  REGION =  'APAC'
GROUP BY MARKET ;

# Q2
-- What is the percentage of unique product increase in 2021 vs. 2020? 
-- The final output contains these fields - 
-- unique_products_2020, unique_products_2021, percentage_chg

with UP2020 as 
(
select count(distinct(p.product_code)) upr2020 from dim_product p 
join fact_sales_monthly s on p.product_code = s.product_code
where fiscal_year = 2020
),
UP2021 as
(
select count(distinct(p.product_code)) upr2021 from dim_product p 
join fact_sales_monthly s on p.product_code = s.product_code
where fiscal_year = 2021
)
select upr2020, upr2021,
round(100 * (upr2021 - upr2020) / upr2020,2)  AS Percentge_change
from UP2020, UP2021;

# Q3
-- Provide a report with all the unique product counts for each segment and
-- sort them in descending order of product counts. 
-- The final output contains 2 fields -  segment,  product_count

SELECT DISTINCT(SEGMENT) , COUNT(distinct(PRODUCT_CODE)) AS PRODUCT_COUNT
FROM dim_product
GROUP BY SEGMENT
ORDER BY COUNT(distinct(PRODUCT_CODE)) DESC;

# Q4 
-- Which segment had the most increase in unique products in 2021 vs 2020? 
-- The final output contains these fields - segment, product_count_2020, product_count_2021, difference

with UP2020 as 
(
select p.segment, count(distinct(p.product_code)) upr2020 from dim_product p 
join fact_sales_monthly s on p.product_code = s.product_code
where fiscal_year = 2020
group by p.segment
),
UP2021 as
(
select p.segment, count(distinct(p.product_code)) upr2021 from dim_product p 
join fact_sales_monthly s on p.product_code = s.product_code
where fiscal_year = 2021
group by p.segment
)
select UP2020.segment, upr2020 as product_count_2020, upr2021 as Product_count_2021,
upr2021 - upr2020  AS Difference
from UP2020 join UP2021 on UP2020.segment = UP2021.segment
order by Difference desc;

# Q5
-- Get the products that have the highest and lowest manufacturing costs.
-- The final output should contain these fields - product_code, product, manufacturing_cost

with MIN_MAX as
(
select p.product_code, p.product, manufacturing_cost ,
RANK() OVER( ORDER BY manufacturing_cost ASC) as rnk
from fact_manufacturing_cost m 
join dim_product p on m.product_code = p.product_code
 ) 
select product_code, product, manufacturing_cost from MIN_MAX 
WHERE rnk = 1 or rnk = (select max(rnk) from MIN_MAX);

# Q6
-- Generate a report which contains the top 5 customers who received an
-- average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market. 
-- The final output contains these fields - customer_code, customer, average_discount_percentage

select fp.customer_code, c.customer, round(avg(pre_invoice_discount_pct), 4) as avg_discount_percentage
from fact_pre_invoice_deductions fp
join dim_customer c on fp.customer_code = c.customer_code
where fiscal_year = 2021 and c.market = "India"
group by c.customer_code, c.customer
order by avg(pre_invoice_discount_pct) desc
limit 5;

# Q7
-- Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month. 
-- This analysis helps to get an idea of low and high-performing months and take strategic decisions.
-- The final report contains these columns: Month, Year, Gross sales Amount

select extract(year from m.date) as year , extract(month from m.date) as month, 
round(sum(sold_quantity*gross_price),0) as gross_sales
from fact_sales_monthly m 
join fact_gross_price g on g.product_code = m.product_code
join dim_customer c on m.customer_code = c.customer_code
where c.customer = "Atliq Exclusive"
group by 1,2
order by 1,2;

# Q8
-- In which quarter of 2020, got the maximum total_sold_quantity? 
-- The final output contains these fields sorted by the total_sold_quantity - Quarter ,total_sold_quantity

select a.quarter q , sum(sold_quantity) sold_quantity 
from
(
select *,
case when month(date) in ( 9,10,11) then "Q1"
 when month(date) in ( 12,1,2) then "Q2"
 when month(date) in ( 3,4,5) then "Q3"
 when month(date) in ( 6,7,8) then "Q4"
else null 
end as quarter
from fact_sales_monthly
) a
where fiscal_year = 2020
group by q
order by sold_quantity desc;

# Q9
-- Which channel helped to bring more gross sales in the fiscal year 2021
-- and the percentage of contribution? The final output contains these fields,channel ,gross_sales_mln, percentage
with grosssale as
(
select c.channel, round(sum(sold_quantity* gross_price), 0) as gross_sales
from fact_sales_monthly s 
join dim_customer c on c.customer_code = s.customer_code
join fact_gross_price g on s.product_code = g.product_code
where s.fiscal_year = 2021
group by channel
order by gross_sales desc
)
select * , round(100 * gross_sales / (select sum(gross_sales) from grosssale),2) as percentage 
from grosssale
group by 1,2,3;

# Q10
-- Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? 
-- The final output contains these fields - division, product_code

select * from (
select p.division,p.product, sum(sold_quantity) sold_quantity,
rank() over(partition by p.division order by sum(sold_quantity) desc) rnk
from fact_sales_monthly s 
join dim_product p on p.product_code = s.product_code
where s.fiscal_year = 2021
group by p.division, p.product
) as a
where rnk <= 3;























