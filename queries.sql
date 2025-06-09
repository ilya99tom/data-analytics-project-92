-- customers_count
-- Запрос выводит количество покупателей
select count(*) as customers_count from customers;

-- top_10_total_income
-- Запрос выводит продавца, количество операций и выручку, сортирует по убыванию выручки, выводит топ-10
select
    concat(e.first_name, ' ', e.last_name) as seller,
    count(s.sales_person_id) as operations,
    floor(sum(coalesce(s.quantity,0) * coalesce(p.price,0))) as income
from employees e
left join sales s
    on e.employee_id = s.sales_person_id
left join products p
    on s.product_id = p.product_id
group by e.employee_id, e.first_name, e.last_name
order by income desc nulls last
limit 10;

-- lowest_average_income
-- Запрос выводит продавцов и среднюю выручку продавца, сортирует по продавцу, выводит продавцов с выручкой ниже средней
select
    concat(e.first_name, ' ', e.last_name) as seller,
    floor(avg(coalesce(s.quantity,0) * coalesce(p.price,0))) as avg_income
from employees e
left join sales s
    on e.employee_id = s.sales_person_id
left join products p
    on s.product_id = p.product_id
group by e.employee_id, e.first_name, e.last_name
having floor(avg(coalesce(s.quantity,0) * coalesce(p.price,0))) < (
    select avg(coalesce(s2.quantity,0) * coalesce(p2.price,0))
    from sales s2
    left join products p2 on s2.product_id = p2.product_id
)
order by avg_income asc;

-- day_of_the_week_income
-- Запрос выводит продавцов, день недели, выручку, сортирует по дню и продавцу
select
    concat(e.first_name, ' ', e.last_name) as seller,
    case to_char(s.sale_date, 'ID')
        when '1' then 'Monday'
        when '2' then 'Tuesday'
        when '3' then 'Wednesday'
        when '4' then 'Thursday'
        when '5' then 'Friday'
        when '6' then 'Saturday'
        when '7' then 'Sunday'
    end as day_of_week,
    floor(sum(coalesce(s.quantity,0) * coalesce(p.price,0))) as income
from employees e
left join sales s
    on e.employee_id = s.sales_person_id
left join products p
    on s.product_id = p.product_id
group by e.employee_id, e.first_name, e.last_name, to_char(s.sale_date, 'ID')
order by to_char(s.sale_date, 'ID'), seller;

-- age_groups
-- Запрос создания временных таблиц, где считается количество участников из возрастных групп
with
y16_25 as (
    select count(*) as age_count from customers where age between 16 and 25
),
y26_40 as (
    select count(*) as age_count from customers where age between 26 and 40
),
y40 as (
    select count(*) as age_count from customers where age > 40
)
select '16-25' as age_category, age_count from y16_25
union all
select '26-40', age_count from y26_40
union all
select '40+', age_count from y40
order by age_category asc;

-- customers_by_month
-- Выводит дату (ГГГГ-ММ), количество уникальных покупателей и выручку
select
    to_char(s.sale_date, 'YYYY-MM') as selling_month,
    count(distinct s.customer_id) as total_customers,
    trunc(sum(coalesce(s.quantity,0) * coalesce(p.price,0))) as income
from sales s
inner join products p on s.product_id = p.product_id
group by to_char(s.sale_date, 'YYYY-MM')
order by selling_month asc;

-- special_offer
-- Поиск клиентов, получивших первый товар с нулевой ценой и их продавцов
with ranked_sales as (
    select
        s.customer_id,
        s.sale_date,
        s.sales_person_id,
        row_number() over (
            partition by s.customer_id
            order by s.sale_date asc, s.sales_id asc
        ) as rn
    from sales s
    inner join products p on s.product_id = p.product_id
    where p.price = 0
)
select
    rs.sale_date,
    c.first_name || ' ' || c.last_name as customer,
    e.first_name || ' ' || e.last_name as seller
from ranked_sales rs
inner join customers c on rs.customer_id = c.customer_id
left join employees e on rs.sales_person_id = e.employee_id
where rs.rn = 1
order by c.customer_id;
