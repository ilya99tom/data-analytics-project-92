--customers_count
--запрос выводит количество покупателей, количество покупателей считается через функцию count()
select count(*) as customers_count from customers;

--top_10_total_income
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

--lowest_average_income
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

--day_of_the_week_income
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
right join sales s 
on s.sales_person_id = e.employee_id
left join products p 
on p.product_id = s.product_id
group by 1, to_char(s.sale_date, 'id')
order by to_char(s.sale_date, 'id') , 1;

--age_groups
with 								/* запрос создания временной таблицы */
y16_25 as ( 
select count(*) as age_count from customers c	/* запрос считает количесвто участников из возрастной группы */
where age between 16 and 25),
y26_40 as (
select count(*) as age_count from customers c	/* запрос считает количесвто участников из возрастной группы */
where age between 26 and 40),
y40 as (
select count(*) as age_count from customers c	/* запрос считает количесвто участников из возрастной группы */
where age > 40)
select '16-25' as age_category, * from y16_25
union								/* запрос объединяет результат 1 запросы со 2 запросом */
select '26-40' as age_category, * from  y26_40
union								/* запрос объединяет результат 1 и 2 запросы с 3 запросом */
select '40+' as age_category, * from  y40
order by 1 asc;						/* сортирует по age_category по возрастанию */

--customers_by_month
select
to_char(sale_date, 'YYYY-MM') as selling_month ,					/* выводит дату в формате ГГГГ-ММ */
count(DISTINCT customer_id) as total_customers,			/* считает количесвто уникальных покупателей */
trunc(sum(s.quantity*p.price)) as income 						/* считает выруку */
from sales s
inner join products p on p.product_id = s.product_id	/* объединяет таблице sales с таблицей products по колонке product_id */
group by selling_month 											/* группирует по дате */
order by selling_month  asc;									/* сортирует по колонке date */

--special_offer
WITH RankedSales AS (
    -- Шаг 1: Находим все продажи с ценой 0 и нумеруем их для каждого клиента по дате
    SELECT
        s.customer_id,
        s.sale_date,
        s.sales_person_id,
        -- Добавляем sales_id на случай, если в один день было несколько продаж с ценой 0
ROW_NUMBER() OVER(PARTITION BY s.customer_id ORDER BY s.sale_date ASC, s.sales_id ASC) as rn
 FROM sales s
    -- Используем INNER JOIN, так как нам нужны только продажи существующих товаров с ценой 0
    INNER JOIN products p ON p.product_id = s.product_id
    WHERE p.price = 0 -- Отбираем только продажи товаров с нулевой ценой
)
-- Шаг 2: Выбираем только самые первые продажи (rn = 1) и присоединяем имена
SELECT
    c.first_name || ' ' || c.last_name as customer,
    rs.sale_date, -- Дата из самой первой продажи
    e.first_name || ' ' || e.last_name as seller -- Продавец из самой первой продажи
FROM RankedSales rs
-- Присоединяем покупателей (INNER JOIN, так как в RankedSales все customer_id существуют и имели продажу с ценой 0)
JOIN customers c ON rs.customer_id = c.customer_id
-- Присоединяем продавцов (LEFT JOIN на случай, если sales_person_id может быть NULL)
LEFT JOIN employees e ON rs.sales_person_id = e.employee_id
WHERE rs.rn = 1 -- ! Вот ключ: оставляем только строку с номером 1 для каждого customer_id
ORDER BY c.customer_id;										/* сортирует по колонке */