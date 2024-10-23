--запрос выводит количество покупателей, количество покупателей считается через функцию count()
select count(*) as customers_count from customers;

/*запрос выводит продавца, количество операций и выручку,
сортирует по убыванию выручки и выводит первые 10 записей*/
select
concat(e.first_name,' ', e.last_name) as seller,
count(s.sales_person_id) as operations,
floor(sum(s.quantity*p.price)) as income
from employees e 
left join sales s 
on s.sales_person_id = e.employee_id  
left join products p 
on p.product_id = s.product_id
group by 1
order by 3 desc nulls last
limit 10;

/*запрос выводит продавцов и среднюю выручку продавца,
 сортирует по продавцу и выводит продавцов у кого
 средняя выручку меньше общей средней выручки*/
select 
concat(e.first_name,' ', e.last_name) as seller,
floor(avg(s.quantity*p.price)) as avg_income
from employees e 
left join sales s 
on s.sales_person_id = e.employee_id
left join products p 
on p.product_id = s.product_id
group by 1
having floor(avg(s.quantity*p.price)) < (select avg(s.quantity*p.price)
from sales s left join products p on p.product_id = s.product_id)
order by 2 asc;

/*запрос выводит продавцов, день недели выручки и выручка,
сортируется по дгям недели и продавцам*/
select 
concat(e.first_name,' ', e.last_name) as seller,
case to_char(s.sale_date, 'id')
when '1' then 'monday'
when '2' then 'tuesday'
when '3' then 'wednesday'
when '4' then 'thursday'
when '5' then 'friday'
when '6' then 'saturday'
when '7' then 'sunday'
end as day_of_week,
floor(sum(s.quantity*p.price)) as income
from employees e 
left join sales s 
on s.sales_person_id = e.employee_id
left join products p 
on p.product_id = s.product_id
group by 1, to_char(s.sale_date, 'id')
order by to_char(s.sale_date, 'id') , 1;
