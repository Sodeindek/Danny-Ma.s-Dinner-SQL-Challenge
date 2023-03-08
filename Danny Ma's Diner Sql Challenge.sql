CREATE SCHEMA dannys_diner;
SET search_path = dannys_diner;

CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
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
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');


  /* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?
-- 2. How many days has each customer visited the restaurant?
-- 3. What was the first item from the menu purchased by each customer?
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
-- 5. Which item was the most popular for each customer?
-- 6. Which item was purchased first by the customer after they became a member?
-- 7. Which item was purchased just before the customer became a member?
-- 8. What is the total items and amount spent for each member before they became a member?
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

--SOLUTIONS
--1
SELECT s.customer_id, SUM(m.price) AS total_spent
FROM dannys_diner.sales s
LEFT JOIN dannys_diner.menu m
USING(product_id)
GROUP BY customer_id
ORDER BY total_spent DESC;
--2
SELECT customer_id, COUNT(DISTINCT order_date) AS num_of_days
FROM dannys_diner.sales s
GROUP BY customer_id
ORDER BY num_of_days DESC;
--3
SELECT customer_id,order_date,items_purchased
FROM (SELECT s.customer_id, s.order_date, array_agg(m.product_name) AS items_purchased, rank () OVER(PARTITION BY customer_id ORDER BY order_date ASC) AS ranking
FROM dannys_diner.sales s
LEFT JOIN dannys_diner.menu m
USING(product_id)
GROUP BY customer_id, order_date) t
WHERE ranking = 1;

--4
SELECT m.product_name,s.product_id, COUNT(s.product_id) AS total_count
FROM dannys_diner.sales s
LEFT JOIN dannys_diner.menu m
USING(product_id)
GROUP BY product_name, s.product_id
ORDER BY total_count DESC;
--5
SELECT customer_id,product_name,items_count
FROM (SELECT s.customer_id, m.product_name, COUNT(m.product_name) AS items_count, rank () OVER(PARTITION BY customer_id ORDER BY COUNT(m.product_name) DESC) AS ranking
FROM dannys_diner.sales s
LEFT JOIN dannys_diner.menu m
USING(product_id)
GROUP BY customer_id, product_name) t1
WHERE ranking = 1
ORDER BY items_count DESC;
--6
WITH new_table AS (SELECT s.customer_id, s.order_date, array_agg(m.product_name) AS items_purchased, rank () OVER(PARTITION BY customer_id ORDER BY order_date ASC) AS ranking
FROM dannys_diner.sales s
LEFT JOIN dannys_diner.menu m
USING(product_id)
WHERE customer_id IN (SELECT customer_id FROM dannys_diner.members)
GROUP BY customer_id, order_date)

SELECT customer_id, order_date,join_date, items_purchased
FROM ( SELECT n.customer_id, n.order_date,m.join_date, n.items_purchased,rank () OVER(PARTITION BY customer_id ORDER BY order_date ASC) AS ranking
FROM new_table AS n
LEFT JOIN dannys_diner.members m
USING(customer_id) 
WHERE n.order_date > m.join_date) t2
WHERE ranking=1;
--7
WITH new_table AS (SELECT s.customer_id, s.order_date, array_agg(m.product_name) AS items_purchased, rank () OVER(PARTITION BY customer_id ORDER BY order_date ASC) AS ranking
FROM dannys_diner.sales s
LEFT JOIN dannys_diner.menu m
USING(product_id)
WHERE customer_id IN (SELECT customer_id FROM dannys_diner.members)
GROUP BY customer_id, order_date)

SELECT customer_id, order_date,join_date, items_purchased
FROM ( SELECT n.customer_id, n.order_date,m.join_date, n.items_purchased,rank () OVER(PARTITION BY customer_id ORDER BY order_date ASC) AS ranking
FROM new_table AS n
LEFT JOIN dannys_diner.members m
USING(customer_id) 
WHERE n.order_date <= m.join_date) t2
ORDER BY customer_id,order_date ASC;
--8
WITH new_table AS (SELECT s.customer_id, s.order_date, COUNT(s.product_id) AS total_products,SUM(m.price) AS total_price, rank () OVER(PARTITION BY customer_id ORDER BY order_date ASC) AS ranking
FROM dannys_diner.sales s
LEFT JOIN dannys_diner.menu m
USING(product_id)
WHERE customer_id IN (SELECT customer_id FROM dannys_diner.members)
GROUP BY customer_id, order_date)

SELECT n.customer_id, SUM(total_products) AS total_products,SUM(total_price) AS total_price
FROM new_table AS n
LEFT JOIN dannys_diner.members m
USING(customer_id) 
WHERE n.order_date <= m.join_date
GROUP BY customer_id
ORDER BY customer_id;
--9
SELECT customer_id, SUM(product_count*point) AS total_points
FROM(SELECT s.customer_id, m.product_name,m.price,COUNT(s.product_id) AS product_count,CASE WHEN m.product_name ='sushi' THEN m.price*2*10 ELSE m.price*10 END AS point
FROM dannys_diner.sales s
LEFT JOIN dannys_diner.menu m
USING(product_id)
GROUP BY customer_id, product_name,price) AS t
GROUP BY customer_id
ORDER BY total_points DESC
--10

