with 								/* запрос создания временной таблицы */
y16_25 as ( 
select count(*) from customers c	/* запрос считает количесвто участников из возрастной группы */
where age between 16 and 25),
y26_40 as (
select count(*) from customers c	/* запрос считает количесвто участников из возрастной группы */
where age between 26 and 40),
y40 as (
select count(*) from customers c	/* запрос считает количесвто участников из возрастной группы */
where age > 40)
select '16-25' as age_category, * from y16_25
union								/* запрос объединяет результат 1 запросы со 2 запросом */
select '26-40' as age_category, * from  y26_40
union								/* запрос объединяет результат 1 и 2 запросы с 3 запросом */
select '40+' as age_category, * from  y40
order by 1 asc;						/* сортирует по age_category по возрастанию */

select
to_char(sale_date, 'YYYY-MM') as date,					/* выводит дату в формате ГГГГ-ММ */
count(DISTINCT customer_id) as total_customers,			/* считает количесвто уникальных покупателей */
sum(s.quantity*p.price) as income 						/* считает выруку */
from sales s
inner join products p on p.product_id = s.product_id	/* объединяет таблице sales с таблицей products по колонке product_id */
group by date											/* группирует по дате */
order by date asc;										/* сортирует по колонке date */

select c.first_name || ' ' || c.last_name as customer,			/* объединяю две колонки в одну */
min(s.sale_date ),												/* находит первую дату */
e.first_name || ' ' || e.last_name as seller					/* объединяю две колонки в одну */
from sales s
inner join customers c on c.customer_id = s.customer_id			/* объединяю таблицы по колонке */
inner join employees e on e.employee_id = s.sales_person_id		/* объединяю таблицы по колонке */
inner join products p on p.product_id = s.product_id			/* объединяю таблицы по колонке */
where p.price = 0												/* фильтрует по условию */
group by customer, seller, c.customer_id						/* группирует по колонке */
order by c.customer_id;											/* сортирует по колонке */