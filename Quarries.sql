--Each of the following case study questions can be answered using a single SQL statement:

--1.What is the total amount each customer spent at the restaurant?
select customer_id ,sum(price) Total_amount_spent from dannys_diner.sales s join dannys_diner.menu m 
on s.product_id=m.product_id group by customer_id order by 2 desc;

--2How many days has each customer visited the restaurant?
select customer_id,count(distinct order_date) Total_number_of_visiting_days from dannys_diner.sales
group by customer_id order by 2 desc;

--3.What was the first item from the menu purchased by each customer?
with cte as (select customer_id,min(order_date) min_date from dannys_diner.sales group by customer_id),
cte2 as (select distinct cte.customer_id,product_name from cte join dannys_diner.sales s on
cte.customer_id=s.customer_id and min_date=order_date join dannys_diner.menu m
on s.product_id=m.product_id)
select customer_id,STRING_AGG(product_name,',') First_items from cte2 group by customer_id order by 1;
--4What is the most purchased item on the menu and how many times was it purchased by all customers?
select top 1 product_name most_purchased_item,count(product_name) Total_purchased_times from 
dannys_diner.sales s join dannys_diner.menu m on s.product_id=m.product_id 
group by product_name order by 2 desc;
--5Which item was the most popular for each customer?
with cte as (select customer_id,product_name,count(product_name) product_purchased_count from dannys_diner.sales s join dannys_diner.menu m 
on s.product_id=m.product_id group by customer_id,product_name),
cte2 as (select * ,rank() over (partition by customer_id order by product_purchased_count desc) rank from cte)
select customer_id,product_name Favorite_products,product_purchased_count from cte2 where rank=1;

--6Which item was purchased first by the customer after they became a member?
with cte as (select s.customer_id,s.order_date ,join_date,m1.product_name,rank() over (partition by s.customer_id order by order_date) rank 
from dannys_diner.sales s join dannys_diner.members m on
s.customer_id=m.customer_id and order_date>=join_date join dannys_diner.menu m1 on s.product_id=m1.product_id)
select customer_id ,product_name First_purchased_item_after_membership,join_date,order_date from cte where rank=1;

--7Which item was purchased just before the customer became a member?
with cte as (select s.customer_id,s.order_date ,join_date,m1.product_name,rank() over (partition by s.customer_id order by order_date desc) rank 
from dannys_diner.sales s join dannys_diner.members m on
s.customer_id=m.customer_id and order_date<join_date join dannys_diner.menu m1 on s.product_id=m1.product_id)
select customer_id ,product_name First_purchased_item_before_membership,order_date,join_date from cte where rank=1;


--8What is the total items and amount spent for each member before they became a member?
with cte as (select s.customer_id,sum(price) amount_spent_before_membership,m1.product_name
from dannys_diner.sales s join dannys_diner.members m on
s.customer_id=m.customer_id and order_date<join_date join dannys_diner.menu m1 on s.product_id=m1.product_id group by s.customer_id,m1.product_name)
select customer_id,sum(amount_spent_before_membership) amount_spent_before_membership,string_agg(product_name,',') as items_before_membership,
count(product_name) as number_of_items_before_membership from cte group by customer_id;

--9If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
select s.customer_id,sum(case when product_name='sushi' then price*20 else price*10 end) total_points from 
dannys_diner.sales s join dannys_diner.menu m on m.product_id=s.product_id 
group by s.customer_id;
--10In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi 
-- how many points do customer A and B have at the end of January?
select s.customer_id,sum(case when datediff(day,join_date,order_date) between 0 and 6 then price*20
when product_name='sushi' then price*20 else price*10 end) total_points from 
dannys_diner.sales s join dannys_diner.menu m on m.product_id=s.product_id join dannys_diner.members m1 on s.customer_id=m1.customer_id
group by s.customer_id;

--    bonus questions
  -- join these for good insight-->
  --1--
 --customer_id	,order_date,	product_name,	price	,member(Y/N)

select s.customer_id,order_date,product_name,case when datediff(day,join_date,order_date)>=0 then 'Y' else 'N' end as member 
from dannys_diner.sales s join dannys_diner.menu m on s.product_id=m.product_id left join dannys_diner.members m1
on s.customer_id=m1.customer_id order by 1,2;
   
   --2--
--customer_id,	order_date	,product_name	,price,	member	,ranking (customer_product)
with cte as (select s.customer_id,order_date,product_name,case when datediff(day,join_date,order_date)>=0 then 'Y' else 'N' end as member 
,row_number() over (partition by s.customer_id order by order_date) row_num
from dannys_diner.sales s join dannys_diner.menu m on s.product_id=m.product_id left join dannys_diner.members m1
on s.customer_id=m1.customer_id),
cte2 as (select cte.customer_id,cte.order_date,cte.product_name,cte.member,DENSE_RANK() over (partition by customer_id order by order_date) ranking,row_num from cte where member='Y')
select cte.*,cte2.ranking from cte left join cte2 on cte.customer_id=cte2.customer_id and cte.row_num=cte2.row_num order by 1,2;
   
