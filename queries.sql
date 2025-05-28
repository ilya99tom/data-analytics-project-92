/*customers_count
запрос выводит количество покупателей,
количество покупателей считается через функцию count()*/
select count(*) as customers_count from customers;

--top_10_total_income
/*запрос выводит продавца, количество операций и выручку,
сортирует по убыванию выручки и выводит первые 10 записей*/
select
    concat(employees.first_name, ' ', employees.last_name) as seller,
    count(sales.sales_person_id) as operations,
    floor(sum(s.quantity * products.price)) as income
from employees
left join sales
    on employees.employee_id = sales.sales_person_id
left join products
    on sales.product_id = products.product_id
group by 1
order by 3 desc nulls last
limit 10;

--lowest_average_income
/*запрос выводит продавцов и среднюю выручку продавца,
 сортирует по продавцу и выводит продавцов у кого
 средняя выручку меньше общей средней выручки*/
select
    concat(e.first_name, ' ', e.last_name) as seller,
    floor(avg(s.quantity * p.price)) as avg_income
from employees as e
left join sales as s
    on e.employee_id = s.sales_person_id
left join products as p
    on s.product_id = p.product_id
group by 1
having
    floor(
        avg(sales.quantity * products.price)) < (
        select avg(sales.quantity * products.price)
        from sales
        left join products
            on sales.product_id = products.product_id
    )
order by 2 asc;

--day_of_the_week_income
/*запрос выводит продавцов, день недели выручки и
сортируется по дням и продавцам*/
select
    concat(e.first_name, ' ', e.last_name) as seller,
    case to_char(s.sale_date, 'id')
        when '1' then 'monday'
        when '2' then 'tuesday'
        when '3' then 'wednesday'
        when '4' then 'thursday'
        when '5' then 'friday'
        when '6' then 'saturday'
        when '7' then 'sunday'
    end as day_of_week,
    floor(sum(s.quantity * p.price)) as income
from employees as e
left join sales as s
    on e.employee_id = s.sales_person_id
left join products as p
    on s.product_id = p.product_id
group by seller, to_char(s.sale_date, 'id')
order by to_char(s.sale_date, 'id'), seller;

--age_groups
/* запрос создания временных таблиц, в котороых
 считается количество участников из возрастных групп*/
with
y16_25 as (
    select count(*) as age_count
    from customers
    where age between 16 and 25
),

y26_40 as (
    select count(*) as age_count
    from customers
    where age between 26 and 40
),

y40 as (
    select count(*) as age_count
    from customers
    where age > 40
)

/* запрос объединяет все временные таблицы*/
select
    '16-25' as age_category,
    *
from y16_25
union
select
    '26-40' as age_category,
    *
from y26_40
union
select
    '40+' as age_category,
    *
from y40
/* сортирует по age_category по возрастанию */
order by 1 asc;		

--customers_by_month
select
/* выводит дату в формате ГГГГ-ММ */
    to_char(s.sale_date, 'YYYY-MM') as selling_month,
    /* считает количесвто уникальных покупателей */
    count(distinct s.customer_id) as total_customers,
    /* считает выруку */
    trunc(sum(s.quantity * p.price)) as income
from sales as s
/* объединяет таблице sales
с таблицей products по колонке product_id */
inner join products as p on s.product_id = p.product_id
/* группирует по дате */
group by selling_month
/* сортирует по колонке date */
order by selling_month asc;

--special_offer
WITH RANKEDSALES AS (
    -- Шаг 1: Находим все продажи с ценой 0
    --и нумеруем их для каждого клиента по дате
    SELECT
        S.CUSTOMER_ID,
        S.SALE_DATE,
        S.SALES_PERSON_ID,
        -- Добавляем sales_id на случай,
        --если в один день было несколько продаж с ценой 0
        ROW_NUMBER()
            OVER (
                PARTITION BY S.CUSTOMER_ID
                ORDER BY S.SALE_DATE ASC, S.SALES_ID ASC
            )
        AS RN
    FROM SALES AS S
    --Используем INNER JOIN,
    --так как нам нужны только продажи существующих товаров с ценой 0
    INNER JOIN PRODUCTS AS P ON S.PRODUCT_ID = P.PRODUCT_ID
    --Отбираем только продажи товаров с нулевой ценой
    WHERE P.PRICE = 0
)
    
-- Шаг 2: Выбираем только самые первые продажи (rn = 1) и присоединяем имена
SELECT
    RS.SALE_DATE,
    -- Дата из самой первой продажи
    C.FIRST_NAME || ' ' || C.LAST_NAME AS CUSTOMER,
    -- Продавец из самой первой продажи
    E.FIRST_NAME || ' ' || E.LAST_NAME AS SELLER
FROM RANKEDSALES AS RS
-- Присоединяем покупателей
INNER JOIN CUSTOMERS AS C ON RS.CUSTOMER_ID = C.CUSTOMER_ID
-- Присоединяем продавцов
LEFT JOIN EMPLOYEES AS E ON RS.SALES_PERSON_ID = E.EMPLOYEE_ID
WHERE RS.RN = 1
/* сортирует по колонке */
ORDER BY C.CUSTOMER_ID;
