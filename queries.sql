-- Количество покупателей
SELECT COUNT(*) AS customers_count
FROM
    customers;

-- Топ 10 продавцов по операциям и выручке
SELECT
    CONCAT(employees.first_name, ' ', employees.last_name) AS seller,
    COUNT(sales.sales_person_id) AS operations,
    FLOOR(
        SUM(
            COALESCE(sales.quantity, 0) * COALESCE(products.price, 0)
        )
    ) AS income
FROM
    sales
LEFT JOIN employees
    ON sales.sales_person_id = employees.employee_id
LEFT JOIN products
    ON sales.product_id = products.product_id
GROUP BY
    employees.first_name,
    employees.last_name
ORDER BY
    income DESC NULLS LAST
LIMIT 10;

-- Продавцы с выручкой ниже среднего
SELECT
    CONCAT(employees.first_name, ' ', employees.last_name) AS seller,
    FLOOR(
        AVG(
            COALESCE(sales.quantity, 0) * COALESCE(products.price, 0)
        )
    ) AS avg_income
FROM
    sales
LEFT JOIN employees
    ON employees.employee_id = sales.sales_person_id
LEFT JOIN products
    ON sales.product_id = products.product_id
GROUP BY
    employees.first_name,
    employees.last_name
HAVING
    FLOOR(
        AVG(
            COALESCE(sales.quantity, 0) * COALESCE(products.price, 0)
        )
    )
    <
    (
        SELECT
            AVG(
                COALESCE(s2.quantity, 0) * COALESCE(p2.price, 0)
            ) AS overall_avg
        FROM
            sales AS s2
        LEFT JOIN products AS p2
            ON s2.product_id = p2.product_id
    )
ORDER BY
    avg_income ASC;

-- Выручка продавцов по дням недели
SELECT
    CONCAT(employees.first_name, ' ', employees.last_name) AS seller,
    CASE EXTRACT(ISODOW FROM sales.sale_date)
        WHEN 1 THEN 'Monday'
        WHEN 2 THEN 'Tuesday'
        WHEN 3 THEN 'Wednesday'
        WHEN 4 THEN 'Thursday'
        WHEN 5 THEN 'Friday'
        WHEN 6 THEN 'Saturday'
        WHEN 7 THEN 'Sunday'
        ELSE 'Unknown'
    END AS day_of_week,
    FLOOR(
        SUM(
            COALESCE(sales.quantity, 0) * COALESCE(products.price, 0)
        )
    ) AS income
FROM
    sales
LEFT JOIN employees
    ON employees.employee_id = sales.sales_person_id
LEFT JOIN products
    ON sales.product_id = products.product_id
GROUP BY
    employees.first_name,
    employees.last_name,
    EXTRACT(ISODOW FROM sales.sale_date)
ORDER BY
    EXTRACT(ISODOW FROM sales.sale_date),
    seller;

-- Количество участников по возрастам
SELECT
    CASE
        WHEN age BETWEEN 16 AND 25 THEN '16-25'
        WHEN age BETWEEN 26 AND 40 THEN '26-40'
        ELSE '40+'
    END AS age_category,
    COUNT(*) AS count_in_group
FROM customers
GROUP BY age_category
ORDER BY age_category ASC;

-- Количество уникальных покупателей и выручка по месяцам
SELECT
    TO_CHAR(sales.sale_date, 'YYYY-MM') AS selling_month,
    COUNT(DISTINCT sales.customer_id) AS total_customers,
    FLOOR(
        SUM(
            COALESCE(sales.quantity, 0) * COALESCE(products.price, 0)
        )
    ) AS income
FROM
    sales
INNER JOIN products
    ON sales.product_id = products.product_id
GROUP BY
    TO_CHAR(sales.sale_date, 'YYYY-MM')
ORDER BY
    selling_month ASC;

-- Клиенты/продавцы первый товар с нулевой ценой
SELECT
    rs.sale_date,
    c.first_name || ' ' || c.last_name AS customer,
    e.first_name || ' ' || e.last_name AS seller
FROM (
    SELECT
        sales.customer_id,
        sales.sale_date,
        sales.sales_person_id,
        ROW_NUMBER() OVER (
            PARTITION BY sales.customer_id
            ORDER BY sales.sale_date ASC
        ) AS rn
    FROM
        sales
    INNER JOIN products
        ON sales.product_id = products.product_id
    WHERE
        products.price = 0
) AS rs
INNER JOIN customers AS c ON rs.customer_id = c.customer_id
LEFT JOIN employees AS e ON rs.sales_person_id = e.employee_id
WHERE
    rs.rn = 1
ORDER BY
    c.customer_id;
