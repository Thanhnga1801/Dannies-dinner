CREATE SCHEMA dannys_diner;
SET search_path = dannys_diner;

CREATE TABLE sales (
  customer_id VARCHAR(1),
  order_date DATE,
  product_id INTEGER
)

INSERT INTO sales
  (customer_id, order_date, product_id)
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3')


CREATE TABLE menu (
  product_id INTEGER,
  product_name VARCHAR(5),
  price INTEGER
);

INSERT INTO menu
  (product_id, product_name, price)
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  
CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);

INSERT INTO members
  (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');

CREATE TABLE menu (
  product_id INTEGER,
  product_name VARCHAR(5),
  price INTEGER
);

INSERT INTO menu
  (product_id, product_name, price)
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12')
## 1. The total amount that each customer spent at the restaurant
WITH ex_1 as(
SELECT sales.customer_id,
	order_date,
	sales.product_id,
	members.join_date,
	product_name,
	price
FROM sales
LEFT JOIN members on members.customer_id = sales.customer_id
LEFT JOIN menu on menu.product_id = sales.product_id
)
### 1. The total amount that each customer spent at the restaurant
SELECT product_id,
price,
count(*) as amount,
count(*) * price as total_money
FROM ex_1
GROUP BY product_id, price
ORDER BY product_id

## 2. How many days has each customer visited each restaurant
WITH ex_2 as(
SELECT sales.customer_id,
	order_date,
	sales.product_id,
	members.join_date,
	product_name,
	price
FROM sales
LEFT JOIN members on members.customer_id = sales.customer_id
LEFT JOIN menu on menu.product_id = sales.product_id
)
SELECT customer_id,
count(order_date)
FROM ex_2
GROUP BY customer_id

### 3. What was the first item from the menu purchased by each customer?
With ranked_sales as (
	SELECT sales.customer_id,
			sales.order_date,
			product_name,
ROW_NUMBER() OVER (PARTITION BY sales.customer_id ORDER BY sales.order_date ASC) as rn
FROM sales
LEFT JOIN menu on menu.product_id = sales.product_id
)

SELECT customer_id,
order_date,
product_name
FROM ranked_sales
WHERE rn = 1

### 4.Which item was the most popular for each customer?
with item_counted as (
SELECT customer_id,
product_name,
count(*) as purchase_count,
row_number () over (partition by customer_id 
					order by count(*) desc) as rn
FROM sales
LEFT JOIN menu on menu.product_id = sales.product_id
GROUP BY customer_id,
product_name
)
SELECT customer_id,
product_name,
purchase_count
FROM item_counted
WHERE rn = 1

### 5. Which item was purchased first by the customer after they became a member?
with ex_5 as (
SELECT sales.customer_id,
order_date,
product_name,
row_number () over (partition by customer_id
					order by order_date ASC) as rn
FROM sales
LEFT JOIN members on members.customer_id = sales.customer_id
LEFT JOIN menu on menu.product_id = sales.product_id
WHERE order_date > join_date
GROUP BY sales.customer_id,
order_date,
product_name
)

SELECT customer_id,
order_date,
product_name
FROM ex_5
WHERE rn = 1

### 6. Which item was purchased just before the customer became a member?
with ex_6 as (
SELECT sales.customer_id,
order_date,
product_name,
row_number () over (partition by customer_id
					order by order_date DESC) as rn
FROM sales
LEFT JOIN members on members.customer_id = sales.customer_id
LEFT JOIN menu on menu.product_id = sales.product_id
WHERE order_date < join_date
GROUP BY sales.customer_id,
order_date,
product_name
)

SELECT customer_id,
order_date,
product_name
FROM ex_6
WHERE rn = 1

## 7. What is the total items and amount spent for each member before they became a member?
with ex_7 as (SELECT sales.customer_id,
product_name,
count(*) as 'total_items_for_each_product_name',
price,
count(*)*price as 'amount_spent_for_each_product_name'
FROM sales
JOIN members on members.customer_id = sales.customer_id
JOIN menu on menu.product_id = sales.product_id
WHERE order_date < join_date
GROUP BY sales.customer_id, 
product_name,
price
ORDER BY sales.customer_id 
)
SELECT customer_id,
sum(total_items_for_each_product_name),
sum(amount_spent_for_each_product_name)
FROM ex_7
GROUP BY customer_id

### 8. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
WITH ex_8 as (SELECT customer_id,
			product_name,
            count(product_name) as 'amount_for_each_product_name',
            price,
            CASE WHEN product_name = 'sushi' then 20*count(product_name)*price
            ELSE 10*count(product_name)*price
            END AS 'Point'
FROM sales
LEFT JOIN menu on menu.product_id = sales.product_id
GROUP BY customer_id,
			product_name,
            price
)
SELECT customer_id,
sum(point) as 'total_points_for_each_customer'
FROM ex_8
GROUP BY customer_id

### 9. In the first week after a customer joins the program (including their join date) 
## they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
SELECT sales.customer_id,
	order_date,
	join_date,
	product_name,
	price,
    count(product_name) as 'amount_for_each_product_name',
    case when order_date <= join_date + 7 then 20*count(product_name)*price
    WHEN product_name = 'sushi' then 20*count(product_name)*price
    ELSE 10*count(product_name)*price
    END AS 'final_points'
FROM sales
JOIN members on members.customer_id = sales.customer_id
JOIN menu on menu.product_id = sales.product_id
WHERE order_date <= '2021-01-31'
GROUP BY sales.customer_id,
			order_date,
            join_date,
            product_name,
            price
ORDER BY sales.customer_id
