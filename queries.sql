-- Количество покупателей
SELECT
    COUNT(*) AS customers_count
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
    employees
LEFT JOIN sales
    ON employees.employee_id = sales.sales_person_id
LEFT JOIN products
    ON sales.product_id = products.product_id
GROUP BY
    employees.employee_id,
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
    employees
LEFT JOIN sales
    ON employees.employee_id = sales.sales_person_id
LEFT JOIN products
    ON sales.product_id = products.product_id
GROUP BY
    employees.employee_id,
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
    CASE TO_CHAR(sales.sale_date, 'ID')
        WHEN '1' THEN 'Monday'
        WHEN '2' THEN 'Tuesday'
        WHEN '3' THEN 'Wednesday'
        WHEN '4' THEN 'Thursday'
        WHEN '5' THEN 'Friday'
        WHEN '6' THEN 'Saturday'
        WHEN '7' THEN 'Sunday'
        ELSE 'Unknown'
    END AS day_of_week,
    FLOOR(
        SUM(
            COALESCE(sales.quantity, 0) * COALESCE(products.price, 0)
        )
    ) AS income
FROM
    employees
LEFT JOIN sales
    ON employees.employee_id = sales.sales_person_id
LEFT JOIN products
    ON sales.product_id = products.product_id
GROUP BY
    employees.employee_id,
    employees.first_name,
    employees.last_name,
    TO_CHAR(sales.sale_date, 'ID')
ORDER BY
    TO_CHAR(sales.sale_date, 'ID'),
    seller;

-- Количество участников по возрастам
WITH y16_25 AS (
    SELECT
        COUNT(*) AS age_count
    FROM
        customers
    WHERE
        customers.age BETWEEN 16 AND 25
),
y26_40 AS (
    SELECT
        COUNT(*) AS age_count
    FROM
        customers
    WHERE
        customers.age BETWEEN 26 AND 40
),
y40 AS (
    SELECT
        COUNT(*) AS age_count
    FROM
        customers
    WHERE
        customers.age > 40
)

SELECT
    '16-25' AS age_category,
    age_count AS count_in_group
FROM
    y16_25

UNION ALL

SELECT
    '26-40' AS age_category,
    age_count AS count_in_group
FROM
    y26_40

UNION ALL

SELECT
    '40+' AS age_category,
    age_count AS count_in_group
FROM
    y40
ORDER BY
    age_category ASC;

-- Количество уникальных покупателей и выручка по месяцам
SELECT
    TO_CHAR(sales.sale_date, 'YYYY-MM') AS selling_month,
    COUNT(DISTINCT sales.customer_id) AS total_customers,
    TRUNC(
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
WITH ranked_sales AS (
    SELECT
        sales.customer_id,
        sales.sale_date,
        sales.sales_person_id,
        ROW_NUMBER() OVER (
            PARTITION BY sales.customer_id
            ORDER BY sales.sale_date ASC, sales.sales_id ASC
        ) AS rn
    FROM
        sales
    INNER JOIN products
        ON sales.product_id = products.product_id
    WHERE
        products.price = 0
)

SELECT
    ranked_sales.sale_date,
    customers.first_name || ' ' || customers.last_name AS customer,
    employees.first_name || ' ' || employees.last_name AS seller
FROM
    ranked_sales
INNER JOIN customers
    ON ranked_sales.customer_id = customers.customer_id
LEFT JOIN employees
    ON ranked_sales.sales_person_id = employees.employee_id
WHERE
    ranked_sales.rn = 1
ORDER BY
    customers.customer_id;
