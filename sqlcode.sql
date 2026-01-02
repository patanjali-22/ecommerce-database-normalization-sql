CREATE TABLE customers (
    customer_id VARCHAR(50) PRIMARY KEY,
    customer_unique_id VARCHAR(50) NOT NULL,
    customer_zip_code_prefix INT NOT NULL,
    customer_city VARCHAR(100),
    customer_state VARCHAR(10)
);

select * from customers;
select count(*) from customers;

CREATE TABLE sellers (
    seller_id VARCHAR(50) PRIMARY KEY,
    seller_zip_code_prefix INT NOT NULL,
    seller_city VARCHAR(100),
    seller_state VARCHAR(10)
);

select * from sellers;
select count(*) from sellers;

CREATE TABLE geolocation (
    geolocation_zip_code_prefix INT NOT NULL,
    geolocation_lat DECIMAL(9,6) NOT NULL,
    geolocation_lng DECIMAL(9,6) NOT NULL,
    geolocation_city VARCHAR(100),
    geolocation_state VARCHAR(10)
);


SELECT geolocation_zip_code_prefix, COUNT(*)
FROM geolocation
GROUP BY geolocation_zip_code_prefix
HAVING COUNT(*) > 1;


DELETE FROM geolocation
WHERE ctid IN (
    SELECT ctid FROM (
        SELECT ctid,
               ROW_NUMBER() OVER (PARTITION BY geolocation_zip_code_prefix ORDER BY ctid) AS rn
        FROM geolocation
    ) t WHERE rn > 1
);

SELECT DISTINCT s.seller_zip_code_prefix
FROM sellers s
LEFT JOIN geolocation g ON s.seller_zip_code_prefix = g.geolocation_zip_code_prefix
WHERE g.geolocation_zip_code_prefix IS NULL;


INSERT INTO geolocation (geolocation_zip_code_prefix, geolocation_lat, geolocation_lng, geolocation_city, geolocation_state)
SELECT DISTINCT seller_zip_code_prefix, 0, 0, 'Unknown', 'XX'
FROM sellers
WHERE seller_zip_code_prefix NOT IN (SELECT geolocation_zip_code_prefix FROM geolocation);

ALTER TABLE geolocation 
ADD CONSTRAINT geolocation_pkey PRIMARY KEY (geolocation_zip_code_prefix);


ALTER TABLE geolocation 
ADD CONSTRAINT geolocation_seller_id_fkey
FOREIGN KEY (geolocation_zip_code_prefix) REFERENCES sellers(seller_zip_code_prefix)
ON DELETE CASCADE 
ON UPDATE CASCADE;

select * from geolocation;

DELETE FROM sellers
WHERE seller_zip_code_prefix NOT IN (SELECT geolocation_zip_code_prefix FROM geolocation);

ALTER TABLE sellers 
ADD CONSTRAINT sellers_geolocation_fkey
FOREIGN KEY (seller_zip_code_prefix) REFERENCES geolocation(geolocation_zip_code_prefix)
ON DELETE SET NULL
ON UPDATE CASCADE;

select * from sellers;


SELECT DISTINCT c.customer_zip_code_prefix
FROM customers c
LEFT JOIN geolocation g ON c.customer_zip_code_prefix = g.geolocation_zip_code_prefix
WHERE g.geolocation_zip_code_prefix IS NULL;

DELETE FROM customers
WHERE customer_zip_code_prefix NOT IN (SELECT geolocation_zip_code_prefix FROM geolocation);

ALTER TABLE customers 
ADD CONSTRAINT customers_geolocation_fkey
FOREIGN KEY (customer_zip_code_prefix) 
REFERENCES geolocation(geolocation_zip_code_prefix)
ON DELETE CASCADE 
ON UPDATE CASCADE;


CREATE TABLE product_category_name_translation (
    product_category_name VARCHAR(100) PRIMARY KEY,
    product_category_name_english VARCHAR(100) NOT NULL
);
select * from product_category_name_translation;

CREATE TABLE products (
    product_id VARCHAR(50) PRIMARY KEY,
    product_category_name VARCHAR(100),
    product_name_length INT,
    product_description_length INT,
    product_photos_qty INT,
    product_weight_g INT,
    product_length_cm INT,
    product_height_cm INT,
    product_width_cm INT   
);
select count(*) from products;
DELETE FROM products
WHERE product_category_name NOT IN (
    SELECT product_category_name FROM product_category_name_translation
)
AND product_category_name IS NOT NULL;


ALTER TABLE products 
ADD CONSTRAINT products_product_category_name_fkey
FOREIGN KEY (product_category_name) 
REFERENCES product_category_name_translation(product_category_name)
ON DELETE SET NULL 
ON UPDATE CASCADE;


CREATE TABLE leads_qualified (
    mql_id VARCHAR(50) PRIMARY KEY,
    first_contact_date TIMESTAMP,
    landing_page_id VARCHAR(50),
    origin VARCHAR(100)
);
select count(*) from leads_qualified;

CREATE TABLE orders (
    order_id VARCHAR(50) PRIMARY KEY,
    customer_id VARCHAR(50) NOT NULL,
    order_status VARCHAR(20) NOT NULL,
    order_purchase_timestamp TIMESTAMP,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
	ON DELETE CASCADE ON UPDATE CASCADE
);
select count(*) from orders;

CREATE TABLE leads_closed (
    mql_id VARCHAR(50) PRIMARY KEY,
    seller_id VARCHAR(50) NOT NULL,
    sdr_id VARCHAR(50) NOT NULL,
    sr_id VARCHAR(50) NOT NULL,
    won_date TIMESTAMP,
    business_segment VARCHAR(100),
    lead_type VARCHAR(100),
    lead_behaviour_profile VARCHAR(100),
    has_company BOOLEAN,
    has_gtin BOOLEAN,
    average_stock VARCHAR(50),
    business_type VARCHAR(100),
    declared_product_catalog_size INT DEFAULT 0,
    declared_monthly_revenue DECIMAL(10,2) DEFAULT 0,
    FOREIGN KEY (mql_id) REFERENCES leads_qualified(mql_id)
	ON DELETE CASCADE ON UPDATE CASCADE
);



SELECT count(DISTINCT lc.seller_id)
FROM leads_closed lc
LEFT JOIN sellers s ON lc.seller_id = s.seller_id
WHERE s.seller_id IS NULL;

DELETE FROM leads_closed
WHERE seller_id NOT IN (SELECT seller_id FROM sellers);

ALTER TABLE leads_closed 
ADD CONSTRAINT leads_closed_seller_id_fkey
FOREIGN KEY (seller_id) REFERENCES sellers(seller_id)
ON DELETE CASCADE 
ON UPDATE CASCADE;


CREATE TABLE order_items (
    order_id VARCHAR(50) NOT NULL,
    order_item_id INT NOT NULL,
    product_id VARCHAR(50) NOT NULL,
    seller_id VARCHAR(50) NOT NULL,
    shipping_limit_date TIMESTAMP,
    price DECIMAL(10,2),
    freight_value DECIMAL(10,2),
    PRIMARY KEY (order_id, order_item_id),
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (seller_id) REFERENCES sellers(seller_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);
select count(*) from order_items;


SELECT count(DISTINCT oi.product_id)
FROM order_items oi
LEFT JOIN products p ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;

DELETE FROM order_items
WHERE product_id NOT IN (
    SELECT product_id FROM products
);

ALTER TABLE order_items 
ADD CONSTRAINT order_items_product_id_fkey
FOREIGN KEY (product_id) REFERENCES products(product_id)
ON DELETE CASCADE 
ON UPDATE CASCADE;


CREATE TABLE order_reviews (
    review_id VARCHAR(50) NOT NULL,
    order_id VARCHAR(50) NOT NULL,
    review_score INT CHECK (review_score BETWEEN 1 AND 5),
    review_comment_title VARCHAR(255),
    review_comment_message TEXT,
    review_creation_date TIMESTAMP,
    review_answer_timestamp TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
	ON DELETE CASCADE ON UPDATE CASCADE
);


select count(*) from order_reviews;

DELETE FROM order_reviews
WHERE review_id IN (
    SELECT review_id
    FROM order_reviews
    GROUP BY review_id
    HAVING COUNT(*) > 1
);


ALTER TABLE order_reviews 
ADD CONSTRAINT order_reviews_pkey PRIMARY KEY (review_id);



CREATE TABLE order_payments (
    order_id VARCHAR(50) NOT NULL,
    payment_sequential INT NOT NULL,
    payment_type VARCHAR(50) NOT NULL,
    payment_installments INT,
    payment_value DECIMAL(10,2),
    PRIMARY KEY (order_id, payment_sequential),
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
	ON DELETE CASCADE ON UPDATE CASCADE
);

select count(*) from order_payments;


ALTER TABLE customers 
DROP COLUMN customer_city, 
DROP COLUMN customer_state;

ALTER TABLE sellers
DROP COLUMN seller_city,
DROP COLUMN seller_state;

