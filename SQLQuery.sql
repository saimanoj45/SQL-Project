--select * from credit_card_transcations

--write a query to print top 5 cities with highest spends and their percentage contribution of total credit card spends 
with top_cities  as (
select top 5 sum(amount) as total_sales from credit_card_transcations
group by city
order by total_sales desc),
total_spends as 
(select SUM(CAST(amount AS BIGINT)) as overal_sale  from credit_card_transcations)
select tc.*, round(tc.total_sales*1.0/tS.overal_sale * 100,2) as percentage_contributer
 from top_cities tc 
inner join total_spends ts
on 1=1;

--write a query to print highest spend month and amount spent in that month for each card type
--select * from credit_card_transcations

with cte1 as (
SELECT  card_type, FORMAT(transaction_date,'MM') AS month_of_date, FORMAT(transaction_date,'yyyy') AS year_of_date, sum(amount) as total_amount 
FROM credit_card_transcations
group by  FORMAT(transaction_date,'MM'),FORMAT(transaction_date,'yyyy'),card_type
),
cte2 as 
(select *,rank() over(partition by card_type order by total_amount desc) as rank 
from cte1)
select * from cte2
where rank = 1;

--write a query to print the transaction details(all columns from the table) for each card type when
--it reaches a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type)
with cte1 as (
select *, sum(amount) over(partition by card_type order by transaction_date,transaction_id) as running_sum 
from credit_card_transcations),
cte2 as (
    select * , rank() over( partition by card_type order by running_sum) as rank  from cte1
where running_sum >= 1000000 )
select * from cte2
where rank =1;

--write a query to find city which had lowest percentage spend for gold card type

with cte1 as (
select card_type,sum(amount) as total_for_cardtype from credit_card_transcations
where card_type='Gold'
group by card_type),
cte2 as (
select card_type,city, sum(amount) as total_for_city from credit_card_transcations
where card_type ='Gold'
group by card_type,city )
select top 1 c2.*,c1. total_for_cardtype,
CAST(total_for_city AS DECIMAL(18,2)) * 100.0 / CAST(total_for_cardtype AS DECIMAL(18,2))as percentage_spend from cte2 c2
inner join cte1 c1
on c1.card_type = c2.card_type
order by percentage_spend asc;

with cte as (
select  city,card_type,sum(amount) as amount
,sum(case when card_type='Gold' then amount end) as gold_amount
from credit_card_transcations
group by city,card_type)
select top 1
city,sum(gold_amount)*1.0/sum(amount) as gold_ratio
from cte
group by city
having sum(gold_amount)is  not null
order by gold_ratio;

--write a query to print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)
with cte1 as(
select city,exp_type, sum(amount) as total_amount
from credit_card_transcations
group by city,exp_type)
,cte2 as(
select *,rank() over(partition by city order by total_amount desc) as rank1 ,
rank() over(partition by city order by total_amount ) as rank2
from cte1) 
select city, max(case when rank1 = 1 then exp_type end) as highest_exp_type,
 max(case when rank2 = 1 then exp_type end) as lowest_exp_type
 from cte2
 group by city;

--write a query to find percentage contribution of spends by females for each expense type

select exp_type,
sum(case when gender='F' then amount else 0 end)*1.0/sum(amount) as percentage_female_contribution
from credit_card_transcations
group by exp_type
order by percentage_female_contribution desc;

--which card and expense type combination saw highest month over month growth in Jan-2014

with cte as (
select card_type,exp_type,datepart(year,transaction_date) yt
,datepart(month,transaction_date) mt,sum(amount) as total_spend
from credit_card_transcations
group by card_type,exp_type,datepart(year,transaction_date),datepart(month,transaction_date)
)
select  top 1 *, (total_spend-prev_mont_spend) as mom_growth
from (
select *
,lag(total_spend,1) over(partition by card_type,exp_type order by yt,mt) as prev_mont_spend
from cte) A
where prev_mont_spend is not null and yt=2014 and mt=1
order by mom_growth desc;

--during weekends which city has highest total spend to total no of transcations ratio 
with cte1 as (
select city,count(transaction_id) as no_of_transactions, 
sum(amount) as total_spend from credit_card_transcations
WHERE DATENAME(WEEKDAY, transaction_date) IN ('Saturday', 'Sunday')
group by city)
select top 1 city,total_spend*1.0/ no_of_transactions as ratio from cte1
order by ratio desc;

--which city took least number of days to reach its 500th transaction after the first transaction in that city

with cte1 as (
    select *,row_number() over(partition by city order by transaction_date,transaction_id) rank  from credit_card_transcations),
cte2 as (
select city,transaction_date,rank from cte1
where rank =500),
cte3 as(select city,transaction_date, rank from cte1 
where rank =1)
select top 1 c2.city,DATEDIFF(DAY, c3.transaction_date, c2.transaction_date) as no_of_days from cte3 c3 inner join cte2 c2
on c2.city =c3.city
order by no_of_days 

