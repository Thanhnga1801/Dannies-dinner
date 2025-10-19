# DANNY DINNER PROJECT
## Introduction
Danny seriously loves Japanese food so in the beginning of 2021, he decides to embark upon a risky venture and opens up a cute little restaurant that sells his 3 favourite foods: sushi, curry and ramen.
Danny’s Diner is in need of your assistance to help the restaurant stay afloat - the restaurant has captured some very basic data from their few months of operation but have no idea how to use their data to help them run the business.
## Dataset
3 key datasets for this case study:
- sales
- menu
- members
### Entity Relationship Diagram
<img width="753" height="379" alt="image" src="https://github.com/user-attachments/assets/1fd4383f-d4b0-49d1-bf53-1203c9b8eee2" />

## Case study questions
**1. The total amount that each customer spent at the restaurant**
```
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

SELECT product_id,
        price,
        count(*) as amount,
        count(*) * price as total_money
FROM ex_1
GROUP BY product_id, price
ORDER BY product_id
```
**2. How many days has each customer visited each restaurant**
```
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
```
**3. What was the first item from the menu purchased by each customer?**
```
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
```
**4. Which item was the most popular for each customer?**
```
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
```
**5. Which item was purchased first by the customer after they became a member?**
```
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
```
**6. Which item was purchased just before the customer became a member?**
```
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
```
**7. What is the total items and amount spent for each member before they became a member?**
```
with ex_7 as (
SELECT sales.customer_id,
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
```
**8. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?**
```
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
```

**9. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?**
```
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
```
