-- SCHEMA CREATION
CREATE SCHEMA lauchpad;

--- TABLE CREATION

CREATE TABLE data.lauchpad.customers (
customer_id SERIAL PRIMARY KEY,
full_name VARCHAR(50) NOT NULL,
email VARCHAR(50) UNIQUE,
join_date DATE NOT NULL
);

CREATE TABLE data.lauchpad.products (
product_id SERIAL PRIMARY KEY,
product_name VARCHAR(50) NOT NULL,
category VARCHAR(50) NOT NULL,
price INTEGER NOT NULL
);


CREATE TABLE data.lauchpad.orders (
order_id SERIAL PRIMARY KEY,
customer_id INTEGER NOT NULL REFERENCES data.lauchpad.customers(customer_id),
order_date DATE NOT NULL,
total_amount INTEGER NOT NULL
);


CREATE TABLE data.lauchpad.order_items (
order_item_id SERIAL PRIMARY KEY,
order_id INTEGER NOT NULL REFERENCES data.lauchpad.orders(order_id),
product_id INTEGER NOT NULL REFERENCES data.lauchpad.products(product_id),
quantity INTEGER NOT NULL,
line_total INTEGER NOT NULL
);


CREATE TABLE data.lauchpad.loyalty_points (
loyalty_id SERIAL PRIMARY KEY,
customer_id INTEGER NOT NULL REFERENCES data.lauchpad.customers(customer_id),
points_earned INTEGER NOT NULL,
transaction_date DATE NOT NULL,
source VARCHAR(50) NOT NULL
);

