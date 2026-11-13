-- Schema for the Brazilian Olist e-commerce dataset (SQLite).
-- Source: Brazilian E-Commerce Public Dataset by Olist (Kaggle:
-- olistbr/brazilian-ecommerce, CC BY-NC-SA 4.0). The CSVs are NOT
-- committed to this repo; run `python src/build_db.py` to download
-- them from the official Olist GitHub mirror and load them here.
-- See README.md for the download URLs.

DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS order_payments;
DROP TABLE IF EXISTS order_reviews;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS category_translation;

CREATE TABLE customers (
    customer_id            TEXT PRIMARY KEY,
    customer_unique_id     TEXT NOT NULL,
    customer_zip_code_prefix INTEGER,
    customer_city          TEXT,
    customer_state         TEXT
);

CREATE TABLE orders (
    order_id                    TEXT PRIMARY KEY,
    customer_id                 TEXT NOT NULL REFERENCES customers(customer_id),
    order_status                TEXT NOT NULL,
    order_purchase_timestamp    TEXT,
    order_approved_at           TEXT,
    order_delivered_carrier_date TEXT,
    order_delivered_customer_date TEXT,
    order_estimated_delivery_date TEXT
);

CREATE TABLE order_items (
    order_id          TEXT NOT NULL REFERENCES orders(order_id),
    order_item_id     INTEGER NOT NULL,
    product_id        TEXT NOT NULL,
    seller_id         TEXT,
    shipping_limit_date TEXT,
    price             REAL NOT NULL,
    freight_value     REAL,
    PRIMARY KEY (order_id, order_item_id)
);

CREATE TABLE order_payments (
    order_id             TEXT NOT NULL REFERENCES orders(order_id),
    payment_sequential   INTEGER NOT NULL,
    payment_type         TEXT NOT NULL,
    payment_installments INTEGER,
    payment_value        REAL NOT NULL,
    PRIMARY KEY (order_id, payment_sequential)
);

CREATE TABLE order_reviews (
    -- NOTE: review_id is NOT unique in the source data: 99,224 rows
    -- contain only 98,410 distinct review_ids (814 duplicates), so
    -- the table uses a surrogate key instead of review_id as PK.
    id                     INTEGER PRIMARY KEY AUTOINCREMENT,
    review_id              TEXT NOT NULL,
    order_id               TEXT NOT NULL REFERENCES orders(order_id),
    review_score           INTEGER,
    review_comment_title   TEXT,
    review_comment_message TEXT,
    review_creation_date   TEXT,
    review_answer_timestamp TEXT
);

CREATE TABLE products (
    product_id               TEXT PRIMARY KEY,
    product_category_name    TEXT,
    product_name_lenght      INTEGER,
    product_description_lenght INTEGER,
    product_photos_qty       INTEGER,
    product_weight_g         REAL,
    product_length_cm        REAL,
    product_height_cm        REAL,
    product_width_cm         REAL
);

CREATE TABLE category_translation (
    product_category_name         TEXT PRIMARY KEY,
    product_category_name_english TEXT NOT NULL
);

CREATE INDEX idx_orders_customer ON orders(customer_id);
CREATE INDEX idx_orders_status ON orders(order_status);
CREATE INDEX idx_orders_purchase ON orders(order_purchase_timestamp);
CREATE INDEX idx_items_order ON order_items(order_id);
CREATE INDEX idx_items_product ON order_items(product_id);
CREATE INDEX idx_payments_order ON order_payments(order_id);
CREATE INDEX idx_reviews_order ON order_reviews(order_id);
CREATE INDEX idx_products_category ON products(product_category_name);
