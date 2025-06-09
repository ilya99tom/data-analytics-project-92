-- customers_count
-- Запрос выводит количество покупателей
SELECT
    COUNT(*) AS customers_count
FROM
    customers;

-- top_10_total_income
-- Запрос выводит продавца, количество операций и выручку, сортирует по убыванию выручки, выводит топ-10
SELECT
    CONCAT(e.first_name, ' ', e.last_name) AS seller,
    COUNT(s.sales_person_id) AS operations,
    FLOOR(
        SUM(
            COALESCE(s.quantity, 0) * COALESCE(p.price, 0)
        )
    ) AS income
FROM
    employees AS e
    LEFT JOIN sales AS s
        ON e.employee_id = s.sales_person_id
    LEFT JOIN products AS p
        ON s.product_id = p.product_id
GROUP BY
    e.employee_id,
    e.first_name,
    e.last_name
ORDER BY
    income DESC NULLS LAST
LIMIT 10;

-- lowest_average_income
-- Запрос выводит продавцов и среднюю выручку продавца, сортирует по продавцу, выводит продавцов с выручкой ниже средней
SELECT
    CONCAT(e.first_name, ' ', e.last_name) AS seller,
    FLOOR(
        AVG(
            COALESCE(s.quantity, 0) * COALESCE(p.price, 0)
        )
    ) AS avg_income
FROM
    employees AS e
    LEFT JOIN sales AS s
        ON e.employee_id = s.sales_person_id
    LEFT JOIN products AS p
        ON s.product_id = p.product_id
GROUP BY
    e.employee_id,
    e.first_name,
    e.last_name
HAVING
    FLOOR(
        AVG(
            COALESCE(s.quantity, 0) * COALESCE(p.price, 0)
        )
    ) <
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

-- day_of_the_week_income
-- Запрос выводит продавцов, день недели, выручку, сортирует по дню и продавцу
SELECT
    CONCAT(e.first_name, ' ', e.last_name) AS seller,
    CASE TO_CHAR(s.sale_date, 'ID')
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
            COALESCE(s.quantity, 0) * COALESCE(p.price, 0)
        )
    ) AS income
FROM
    employees AS e
    LEFT JOIN sales AS s
        ON e.employee_id = s.sales_person_id
    LEFT JOIN products AS p
        ON s.product_id = p.product_id
GROUP BY
    e.employee_id,
    e.first_name,
    e.last_name,
    TO_CHAR(s.sale_date, 'ID')
ORDER BY
    TO_CHAR(s.sale_date, 'ID'),
    seller;

-- age_groups
-- Запрос создания временных таблиц, где считается количество участников из возрастных групп
WITH y16_25 AS (
    SELECT
        COUNT(*) AS age_count
    FROM
        customers AS c1
    WHERE
        c1.age BETWEEN 16 AND 25
),
y26_40 AS (
    SELECT
        COUNT(*) AS age_count
    FROM
        customers AS c2
    WHERE
        c2.age BETWEEN 26 AND 40
),
y40 AS (
    SELECT
        COUNT(*) AS age_count
    FROM
        customers AS c3
    WHERE
        c3.age > 40
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

-- customers_by_month
-- Выводит дату (ГГГГ-ММ), количество уникальных покупателей и выручку
SELECT
    TO_CHAR(s.sale_date, 'YYYY-MM') AS selling_month,
    COUNT(DISTINCT s.customer_id) AS total_customers,
    TRUNC(
        SUM(
            COALESCE(s.quantity, 0) * COALESCE(p.price, 0)
        )
    ) AS income
FROM
    sales AS s
    INNER JOIN products AS p
        ON s.product_id = p.product_id
GROUP BY
    TO_CHAR(s.sale_date, 'YYYY-MM')
ORDER BY
    selling_month ASC;

-- special_offer
-- Поиск клиентов, получивших первый товар с нулевой ценой и их продавцов
WITH ranked_sales AS (
    SELECT
        s.customer_id AS customer_id,
        s.sale_date AS sale_date,
        s.sales_person_id AS sales_person_id,
        ROW_NUMBER() OVER (
            PARTITION BY s.customer_id
            ORDER BY s.sale_date ASC, s.sales_id ASC
        ) AS rn
    FROM
        sales AS s
        INNER JOIN products AS p
            ON s.product_id = p.product_id
    WHERE
        p.price = 0
)
SELECT
    rs.sale_date AS sale_date,
    c.first_name || ' ' || c.last_name AS customer,
    e.first_name || ' ' || e.last_name AS seller
FROM
    ranked_sales AS rs
    INNER JOIN customers AS c
        ON rs.customer_id = c.customer_id
    LEFT JOIN employees AS e
        ON rs.sales_person_id = e.employee_id
WHERE
    rs.rn = 1
ORDER BY
    c.customer_id;
