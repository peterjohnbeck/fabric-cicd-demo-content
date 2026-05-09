-- DDL

CREATE SCHEMA OLTP_Tables;

CREATE TABLE OLTP_Tables.country (
    country_id   INT          NOT NULL,
    country_name VARCHAR(100) NOT NULL,
    country_code CHAR(2)      NOT NULL
);

ALTER TABLE OLTP_Tables.country
    ADD CONSTRAINT PK_country PRIMARY KEY NONCLUSTERED (country_id) NOT ENFORCED;

ALTER TABLE OLTP_Tables.country
    ADD CONSTRAINT UQ_country_code UNIQUE NONCLUSTERED (country_code) NOT ENFORCED;


CREATE TABLE OLTP_Tables.state (
    state_id     INT          NOT NULL,
    state_name   VARCHAR(100) NOT NULL,
    state_code   CHAR(2)      NOT NULL,
    country_id   INT          NOT NULL
);

ALTER TABLE OLTP_Tables.state
    ADD CONSTRAINT PK_state PRIMARY KEY NONCLUSTERED (state_id) NOT ENFORCED;

ALTER TABLE OLTP_Tables.state
    ADD CONSTRAINT FK_state_country FOREIGN KEY (country_id)
    REFERENCES OLTP_Tables.country (country_id) NOT ENFORCED;


CREATE TABLE OLTP_Tables.city (
    city_id   INT          NOT NULL,
    city_name VARCHAR(100) NOT NULL,
    state_id  INT          NOT NULL
);

ALTER TABLE OLTP_Tables.city
    ADD CONSTRAINT PK_city PRIMARY KEY NONCLUSTERED (city_id) NOT ENFORCED;

ALTER TABLE OLTP_Tables.city
    ADD CONSTRAINT FK_city_state FOREIGN KEY (state_id)
    REFERENCES OLTP_Tables.state (state_id) NOT ENFORCED;


CREATE TABLE OLTP_Tables.address (
    address_id   INT          NOT NULL,
    street_line1 VARCHAR(200) NOT NULL,
    street_line2 VARCHAR(200),
    postal_code  VARCHAR(20)  NOT NULL,
    city_id      INT          NOT NULL
);

ALTER TABLE OLTP_Tables.address
    ADD CONSTRAINT PK_address PRIMARY KEY NONCLUSTERED (address_id) NOT ENFORCED;

ALTER TABLE OLTP_Tables.address
    ADD CONSTRAINT FK_address_city FOREIGN KEY (city_id)
    REFERENCES OLTP_Tables.city (city_id) NOT ENFORCED;


CREATE TABLE OLTP_Tables.customer (
    customer_id   INT             NOT NULL,
    first_name    VARCHAR(100)    NOT NULL,
    last_name     VARCHAR(100)    NOT NULL,
    email         VARCHAR(255)    NOT NULL,
    phone         VARCHAR(30),
    date_of_birth DATE,
    address_id    INT             NOT NULL,
    created_at    DATETIME2(0)    NOT NULL
);

ALTER TABLE OLTP_Tables.customer
    ADD CONSTRAINT PK_customer PRIMARY KEY NONCLUSTERED (customer_id) NOT ENFORCED;

ALTER TABLE OLTP_Tables.customer
    ADD CONSTRAINT UQ_customer_email UNIQUE NONCLUSTERED (email) NOT ENFORCED;

ALTER TABLE OLTP_Tables.customer
    ADD CONSTRAINT FK_customer_address FOREIGN KEY (address_id)
    REFERENCES OLTP_Tables.address (address_id) NOT ENFORCED;


-- INSERT statements

INSERT INTO OLTP_Tables.country (country_id, country_name, country_code) VALUES
    (1, 'United States',  'US'),
    (2, 'Canada',         'CA'),
    (3, 'United Kingdom', 'GB');

INSERT INTO OLTP_Tables.state (state_id, state_name, state_code, country_id) VALUES
    (1, 'California',       'CA', 1),
    (2, 'Texas',            'TX', 1),
    (3, 'New York',         'NY', 1),
    (4, 'Florida',          'FL', 1),
    (5, 'Illinois',         'IL', 1),
    (6, 'Ontario',          'ON', 2),
    (7, 'British Columbia', 'BC', 2),
    (8, 'England',          'EN', 3);

INSERT INTO OLTP_Tables.city (city_id, city_name, state_id) VALUES
    (1,  'Los Angeles',   1),
    (2,  'San Francisco', 1),
    (3,  'Houston',       2),
    (4,  'Austin',        2),
    (5,  'New York City', 3),
    (6,  'Miami',         4),
    (7,  'Chicago',       5),
    (8,  'Toronto',       6),
    (9,  'Vancouver',     7),
    (10, 'London',        8);

INSERT INTO OLTP_Tables.address (address_id, street_line1, street_line2, postal_code, city_id) VALUES
    (1,  '123 Sunset Blvd',    NULL,        '90028',   1),
    (2,  '456 Market St',      'Apt 12',    '94105',   2),
    (3,  '789 Westheimer Rd',  NULL,        '77056',   3),
    (4,  '321 Congress Ave',   'Suite 200', '78701',   4),
    (5,  '555 5th Avenue',     'Floor 10',  '10017',   5),
    (6,  '88 Brickell Ave',    NULL,        '33131',   6),
    (7,  '200 N Michigan Ave', 'Apt 34',    '60601',   7),
    (8,  '10 King St W',       NULL,        'M5H1A1',  8),
    (9,  '980 Granville St',   'Unit 5',    'V6Z1L3',  9),
    (10, '42 Baker Street',    NULL,        'NW1 6XE', 10);

INSERT INTO OLTP_Tables.customer (customer_id, first_name, last_name, email, phone, date_of_birth, address_id, created_at) VALUES
    (1,  'James',   'Anderson',  'james.anderson@email.com',  '+1-310-555-0101', '1985-03-14', 1,  '2024-01-15 08:30:00'),
    (2,  'Sarah',   'Mitchell',  'sarah.mitchell@email.com',  '+1-415-555-0182', '1990-07-22', 2,  '2024-01-22 11:15:00'),
    (3,  'Carlos',  'Rivera',    'carlos.rivera@email.com',   '+1-713-555-0143', '1978-11-05', 3,  '2024-02-03 09:45:00'),
    (4,  'Emily',   'Chen',      'emily.chen@email.com',      '+1-512-555-0167', '1995-01-30', 4,  '2024-02-18 14:00:00'),
    (5,  'Michael', 'Okafor',    'michael.okafor@email.com',  '+1-212-555-0134', '1982-09-18', 5,  '2024-03-05 10:30:00'),
    (6,  'Laura',   'Fernandez', 'laura.fernandez@email.com', '+1-305-555-0121', '1993-04-25', 6,  '2024-03-12 16:20:00'),
    (7,  'David',   'Park',      'david.park@email.com',      '+1-312-555-0198', '1988-12-03', 7,  '2024-04-01 08:00:00'),
    (8,  'Priya',   'Sharma',    'priya.sharma@email.com',    '+1-416-555-0155', '1991-06-11', 8,  '2024-04-14 13:45:00'),
    (9,  'Liam',    'Tremblay',  'liam.tremblay@email.com',   '+1-604-555-0177', '1987-02-28', 9,  '2024-05-02 09:10:00'),
    (10, 'Sophie',  'Williams',  'sophie.williams@email.com', '+44-20-5550-0162','1996-08-09', 10, '2024-05-20 11:55:00');
	
	
-- DDL

CREATE TABLE OLTP_Tables.product_category (
    category_id   INT          NOT NULL,
    category_name VARCHAR(100) NOT NULL
);

ALTER TABLE OLTP_Tables.product_category
    ADD CONSTRAINT PK_product_category PRIMARY KEY NONCLUSTERED (category_id) NOT ENFORCED;

ALTER TABLE OLTP_Tables.product_category
    ADD CONSTRAINT UQ_product_category_name UNIQUE NONCLUSTERED (category_name) NOT ENFORCED;


CREATE TABLE OLTP_Tables.brand (
    brand_id   INT          NOT NULL,
    brand_name VARCHAR(100) NOT NULL,
    country_id INT          NOT NULL
);

ALTER TABLE OLTP_Tables.brand
    ADD CONSTRAINT PK_brand PRIMARY KEY NONCLUSTERED (brand_id) NOT ENFORCED;

ALTER TABLE OLTP_Tables.brand
    ADD CONSTRAINT UQ_brand_name UNIQUE NONCLUSTERED (brand_name) NOT ENFORCED;

ALTER TABLE OLTP_Tables.brand
    ADD CONSTRAINT FK_brand_country FOREIGN KEY (country_id)
    REFERENCES OLTP_Tables.country (country_id) NOT ENFORCED;


CREATE TABLE OLTP_Tables.unit_of_measure (
    uom_id   INT         NOT NULL,
    uom_code VARCHAR(20) NOT NULL,
    uom_desc VARCHAR(100) NOT NULL
);

ALTER TABLE OLTP_Tables.unit_of_measure
    ADD CONSTRAINT PK_unit_of_measure PRIMARY KEY NONCLUSTERED (uom_id) NOT ENFORCED;

ALTER TABLE OLTP_Tables.unit_of_measure
    ADD CONSTRAINT UQ_uom_code UNIQUE NONCLUSTERED (uom_code) NOT ENFORCED;


CREATE TABLE OLTP_Tables.product_status (
    status_id   INT         NOT NULL,
    status_name VARCHAR(50) NOT NULL
);

ALTER TABLE OLTP_Tables.product_status
    ADD CONSTRAINT PK_product_status PRIMARY KEY NONCLUSTERED (status_id) NOT ENFORCED;

ALTER TABLE OLTP_Tables.product_status
    ADD CONSTRAINT UQ_product_status_name UNIQUE NONCLUSTERED (status_name) NOT ENFORCED;


CREATE TABLE OLTP_Tables.product (
    product_id       INT             NOT NULL,
    sku              VARCHAR(50)     NOT NULL,
    product_name     VARCHAR(200)    NOT NULL,
    brand_id         INT             NOT NULL,
    category_id      INT             NOT NULL,
    status_id        INT             NOT NULL,
    unit_price       DECIMAL(10, 2)  NOT NULL,
    uom_id           INT             NOT NULL,
    weight_kg        DECIMAL(8, 3),
    warranty_months  SMALLINT,
    introduced_date  DATE
);

ALTER TABLE OLTP_Tables.product
    ADD CONSTRAINT PK_product PRIMARY KEY NONCLUSTERED (product_id) NOT ENFORCED;

ALTER TABLE OLTP_Tables.product
    ADD CONSTRAINT UQ_product_sku UNIQUE NONCLUSTERED (sku) NOT ENFORCED;

ALTER TABLE OLTP_Tables.product
    ADD CONSTRAINT FK_product_brand FOREIGN KEY (brand_id)
    REFERENCES OLTP_Tables.brand (brand_id) NOT ENFORCED;

ALTER TABLE OLTP_Tables.product
    ADD CONSTRAINT FK_product_category FOREIGN KEY (category_id)
    REFERENCES OLTP_Tables.product_category (category_id) NOT ENFORCED;

ALTER TABLE OLTP_Tables.product
    ADD CONSTRAINT FK_product_status FOREIGN KEY (status_id)
    REFERENCES OLTP_Tables.product_status (status_id) NOT ENFORCED;

ALTER TABLE OLTP_Tables.product
    ADD CONSTRAINT FK_product_uom FOREIGN KEY (uom_id)
    REFERENCES OLTP_Tables.unit_of_measure (uom_id) NOT ENFORCED;


-- INSERT statements

INSERT INTO OLTP_Tables.product_category (category_id, category_name) VALUES
    (1, 'Smartphone'),
    (2, 'Laptop'),
    (3, 'Tablet'),
    (4, 'Smartwatch'),
    (5, 'Headphones'),
    (6, 'Television'),
    (7, 'Gaming Console');

INSERT INTO OLTP_Tables.brand (brand_id, brand_name, country_id) VALUES
    (1, 'Apple',   1),
    (2, 'Samsung', 1),
    (3, 'Sony',    1),
    (4, 'Microsoft',1),
    (5, 'LG',      1),
    (6, 'Bose',    1);

INSERT INTO OLTP_Tables.unit_of_measure (uom_id, uom_code, uom_desc) VALUES
    (1, 'EA', 'Each');

INSERT INTO OLTP_Tables.product_status (status_id, status_name) VALUES
    (1, 'Active'),
    (2, 'Discontinued'),
    (3, 'Coming Soon');

INSERT INTO OLTP_Tables.product (product_id, sku, product_name, brand_id, category_id, status_id, unit_price, uom_id, weight_kg, warranty_months, introduced_date) VALUES
    (1,  'APL-IPH15PM',  'iPhone 15 Pro Max',               1, 1, 1, 1199.00, 1, 0.221, 12, '2023-09-22'),
    (2,  'APL-IPH15',    'iPhone 15',                       1, 1, 1,  799.00, 1, 0.171, 12, '2023-09-22'),
    (3,  'SAM-GS24U',    'Samsung Galaxy S24 Ultra',         2, 1, 1, 1299.00, 1, 0.232, 12, '2024-01-17'),
    (4,  'SAM-GS24',     'Samsung Galaxy S24',               2, 1, 1,  799.00, 1, 0.167, 12, '2024-01-17'),
    (5,  'APL-MBP14M3',  'MacBook Pro 14 M3 Pro',           1, 2, 1, 1999.00, 1, 1.610, 12, '2023-11-07'),
    (6,  'APL-MBA15M3',  'MacBook Air 15 M3',               1, 2, 1, 1299.00, 1, 1.510, 12, '2024-03-08'),
    (7,  'MSF-SL9',      'Microsoft Surface Laptop 6',      4, 2, 1, 1299.00, 1, 1.340, 12, '2024-04-09'),
    (8,  'SAM-G9TB',     'Samsung Galaxy Tab S9',            2, 3, 1,  699.00, 1, 0.498, 12, '2023-08-11'),
    (9,  'APL-IPPM6',    'iPad Pro M4 13-inch',             1, 3, 1, 1099.00, 1, 0.682, 12, '2024-05-15'),
    (10, 'APL-AW9',      'Apple Watch Series 9',            1, 4, 1,  399.00, 1, 0.039, 12, '2023-09-22'),
    (11, 'APL-AWUP',     'Apple Watch Ultra 2',             1, 4, 1,  799.00, 1, 0.061, 12, '2023-09-22'),
    (12, 'SAM-GW6CL',    'Samsung Galaxy Watch 6 Classic',  2, 4, 1,  399.00, 1, 0.059, 12, '2023-08-11'),
    (13, 'SON-WH1000XM5','Sony WH-1000XM5',                 3, 5, 1,  349.00, 1, 0.250, 12, '2022-05-20'),
    (14, 'APL-AIRPODSP3','AirPods Pro 2nd Gen',             1, 5, 1,  249.00, 1, 0.051, 12, '2022-09-23'),
    (15, 'BOS-QC45',     'Bose QuietComfort 45',            6, 5, 1,  279.00, 1, 0.238, 12, '2021-09-23'),
    (16, 'BOS-QCU',      'Bose QuietComfort Ultra',         6, 5, 1,  429.00, 1, 0.254, 12, '2023-10-19'),
    (17, 'SON-A95L65',   'Sony Bravia XR A95L 65-inch',     3, 6, 1, 2999.00, 1, 28.600, 12, '2023-04-01'),
    (18, 'SAM-QN90C65',  'Samsung Neo QLED QN90C 65-inch',  2, 6, 1, 1799.00, 1, 24.500, 12, '2023-03-15'),
    (19, 'LGE-C365',     'LG OLED C3 65-inch',              5, 6, 1, 1599.00, 1, 22.700, 12, '2023-02-20'),
    (20, 'MSF-XSX',      'Xbox Series X',                   4, 7, 1,  499.00, 1, 4.450, 12, '2020-11-10');

-- DDL

CREATE TABLE OLTP_Tables.sales_order (
    order_id       INT           NOT NULL,
    customer_id    INT           NOT NULL,
    order_date     DATE          NOT NULL,
    ship_date      DATE,
    order_status   VARCHAR(20)   NOT NULL
);

ALTER TABLE OLTP_Tables.sales_order
    ADD CONSTRAINT PK_sales_order PRIMARY KEY NONCLUSTERED (order_id) NOT ENFORCED;

ALTER TABLE OLTP_Tables.sales_order
    ADD CONSTRAINT FK_sales_order_customer FOREIGN KEY (customer_id)
    REFERENCES OLTP_Tables.customer (customer_id) NOT ENFORCED;


CREATE TABLE OLTP_Tables.sales_order_line (
    order_line_id  INT            NOT NULL,
    order_id       INT            NOT NULL,
    product_id     INT            NOT NULL,
    quantity       SMALLINT       NOT NULL,
    unit_price     DECIMAL(10, 2) NOT NULL,
    discount_pct   DECIMAL(5, 2)  NOT NULL,
    line_total     DECIMAL(10, 2) NOT NULL
);

ALTER TABLE OLTP_Tables.sales_order_line
    ADD CONSTRAINT PK_sales_order_line PRIMARY KEY NONCLUSTERED (order_line_id) NOT ENFORCED;

ALTER TABLE OLTP_Tables.sales_order_line
    ADD CONSTRAINT FK_sol_order FOREIGN KEY (order_id)
    REFERENCES OLTP_Tables.sales_order (order_id) NOT ENFORCED;

ALTER TABLE OLTP_Tables.sales_order_line
    ADD CONSTRAINT FK_sol_product FOREIGN KEY (product_id)
    REFERENCES OLTP_Tables.product (product_id) NOT ENFORCED;


-- INSERT statements
-- Date range: 2022-01-01 to 2024-12-31
-- Product availability respected (introduced_date):
--   Sony WH-1000XM5    available from 2022-05-20  (product_id 13)
--   AirPods Pro 2      available from 2022-09-23  (product_id 14)
--   Bose QC45          available from 2021-09-23  (product_id 15) - full range
--   Xbox Series X      available from 2020-11-10  (product_id 20) - full range
--   All other products available from 2023 onwards
-- Seasonality: Q4 (Oct-Dec) peaks for holiday shopping; Q1 dip; Q3 modest back-to-school bump
-- Trend: volume grows year-on-year as retailer matures
-- Small retailer: typically 1-2 items per order, occasional multi-line orders
-- Discounts applied selectively (Black Friday, clearance)

INSERT INTO OLTP_Tables.sales_order (order_id, customer_id, order_date, ship_date, order_status) VALUES
-- 2022: limited product range (only products 13,14,15,20 available by end of year)
    (1,   3,  '2022-01-08', '2022-01-11', 'Completed'),
    (2,   7,  '2022-01-19', '2022-01-22', 'Completed'),
    (3,   1,  '2022-02-14', '2022-02-17', 'Completed'),
    (4,   9,  '2022-03-05', '2022-03-08', 'Completed'),
    (5,   5,  '2022-03-22', '2022-03-25', 'Completed'),
    (6,   2,  '2022-04-10', '2022-04-13', 'Completed'),
    (7,   6,  '2022-04-28', '2022-05-01', 'Completed'),
    (8,   10, '2022-06-03', '2022-06-06', 'Completed'),
    (9,   4,  '2022-06-18', '2022-06-21', 'Completed'),
    (10,  8,  '2022-07-04', '2022-07-07', 'Completed'),
    (11,  1,  '2022-07-22', '2022-07-25', 'Completed'),
    (12,  3,  '2022-08-09', '2022-08-12', 'Completed'),
    (13,  5,  '2022-08-30', '2022-09-02', 'Completed'),
    (14,  7,  '2022-09-15', '2022-09-18', 'Completed'),
    (15,  2,  '2022-10-04', '2022-10-07', 'Completed'),
    (16,  9,  '2022-10-19', '2022-10-22', 'Completed'),
    (17,  6,  '2022-11-02', '2022-11-05', 'Completed'),
    (18,  4,  '2022-11-11', '2022-11-14', 'Completed'),
    (19,  10, '2022-11-25', '2022-11-28', 'Completed'),  -- Black Friday
    (20,  1,  '2022-11-25', '2022-11-28', 'Completed'),  -- Black Friday
    (21,  3,  '2022-11-26', '2022-11-29', 'Completed'),  -- Black Friday weekend
    (22,  8,  '2022-12-02', '2022-12-05', 'Completed'),
    (23,  5,  '2022-12-08', '2022-12-11', 'Completed'),
    (24,  2,  '2022-12-12', '2022-12-15', 'Completed'),
    (25,  7,  '2022-12-16', '2022-12-19', 'Completed'),
    (26,  9,  '2022-12-19', '2022-12-22', 'Completed'),
    (27,  4,  '2022-12-20', '2022-12-23', 'Completed'),
    (28,  6,  '2022-12-21', '2022-12-24', 'Completed'),

-- 2023: most products launch during year; volume grows
    (29,  1,  '2023-01-05', '2023-01-08', 'Completed'),
    (30,  10, '2023-01-14', '2023-01-17', 'Completed'),
    (31,  3,  '2023-02-02', '2023-02-05', 'Completed'),
    (32,  5,  '2023-02-18', '2023-02-21', 'Completed'),
    (33,  8,  '2023-03-07', '2023-03-10', 'Completed'),
    (34,  2,  '2023-03-20', '2023-03-23', 'Completed'),
    (35,  7,  '2023-04-06', '2023-04-09', 'Completed'),
    (36,  4,  '2023-04-22', '2023-04-25', 'Completed'),
    (37,  9,  '2023-05-10', '2023-05-13', 'Completed'),
    (38,  6,  '2023-05-25', '2023-05-28', 'Completed'),
    (39,  1,  '2023-06-08', '2023-06-11', 'Completed'),
    (40,  3,  '2023-06-21', '2023-06-24', 'Completed'),
    (41,  10, '2023-07-04', '2023-07-07', 'Completed'),
    (42,  5,  '2023-07-18', '2023-07-21', 'Completed'),
    (43,  2,  '2023-08-03', '2023-08-06', 'Completed'),
    (44,  8,  '2023-08-14', '2023-08-17', 'Completed'),  -- back to school
    (45,  7,  '2023-08-22', '2023-08-25', 'Completed'),  -- back to school
    (46,  4,  '2023-09-05', '2023-09-08', 'Completed'),
    (47,  9,  '2023-09-25', '2023-09-28', 'Completed'),  -- iPhone 15 launch
    (48,  1,  '2023-09-26', '2023-09-29', 'Completed'),  -- iPhone 15 launch
    (49,  6,  '2023-09-27', '2023-09-30', 'Completed'),  -- iPhone 15 launch
    (50,  3,  '2023-10-05', '2023-10-08', 'Completed'),
    (51,  10, '2023-10-18', '2023-10-21', 'Completed'),
    (52,  5,  '2023-11-02', '2023-11-05', 'Completed'),
    (53,  2,  '2023-11-14', '2023-11-17', 'Completed'),
    (54,  8,  '2023-11-24', '2023-11-27', 'Completed'),  -- Black Friday
    (55,  7,  '2023-11-24', '2023-11-27', 'Completed'),  -- Black Friday
    (56,  4,  '2023-11-24', '2023-11-27', 'Completed'),  -- Black Friday
    (57,  9,  '2023-11-25', '2023-11-28', 'Completed'),  -- Black Friday weekend
    (58,  1,  '2023-11-25', '2023-11-28', 'Completed'),  -- Black Friday weekend
    (59,  6,  '2023-12-01', '2023-12-04', 'Completed'),
    (60,  3,  '2023-12-07', '2023-12-10', 'Completed'),
    (61,  10, '2023-12-11', '2023-12-14', 'Completed'),
    (62,  5,  '2023-12-14', '2023-12-17', 'Completed'),
    (63,  2,  '2023-12-16', '2023-12-19', 'Completed'),
    (64,  8,  '2023-12-18', '2023-12-21', 'Completed'),
    (65,  7,  '2023-12-19', '2023-12-22', 'Completed'),
    (66,  4,  '2023-12-20', '2023-12-23', 'Completed'),
    (67,  9,  '2023-12-21', '2023-12-24', 'Completed'),

-- 2024: full product range, highest volume, strongest seasonality
    (68,  1,  '2024-01-06', '2024-01-09', 'Completed'),
    (69,  10, '2024-01-18', '2024-01-21', 'Completed'),
    (70,  3,  '2024-02-03', '2024-02-06', 'Completed'),
    (71,  5,  '2024-02-15', '2024-02-18', 'Completed'),  -- Valentine's Day
    (72,  2,  '2024-02-15', '2024-02-18', 'Completed'),  -- Valentine's Day
    (73,  8,  '2024-03-08', '2024-03-11', 'Completed'),
    (74,  7,  '2024-03-22', '2024-03-25', 'Completed'),
    (75,  4,  '2024-04-05', '2024-04-08', 'Completed'),
    (76,  9,  '2024-04-19', '2024-04-22', 'Completed'),
    (77,  6,  '2024-05-03', '2024-05-06', 'Completed'),
    (78,  1,  '2024-05-16', '2024-05-19', 'Completed'),  -- iPad Pro M4 launch
    (79,  3,  '2024-05-17', '2024-05-20', 'Completed'),  -- iPad Pro M4 launch
    (80,  10, '2024-06-07', '2024-06-10', 'Completed'),
    (81,  5,  '2024-06-21', '2024-06-24', 'Completed'),
    (82,  2,  '2024-07-04', '2024-07-07', 'Completed'),
    (83,  8,  '2024-07-19', '2024-07-22', 'Completed'),
    (84,  7,  '2024-08-02', '2024-08-05', 'Completed'),
    (85,  4,  '2024-08-13', '2024-08-16', 'Completed'),  -- back to school
    (86,  9,  '2024-08-20', '2024-08-23', 'Completed'),  -- back to school
    (87,  6,  '2024-08-28', '2024-08-31', 'Completed'),  -- back to school
    (88,  1,  '2024-09-06', '2024-09-09', 'Completed'),
    (89,  3,  '2024-09-20', '2024-09-23', 'Completed'),
    (90,  10, '2024-10-04', '2024-10-07', 'Completed'),
    (91,  5,  '2024-10-17', '2024-10-20', 'Completed'),
    (92,  2,  '2024-10-31', '2024-11-03', 'Completed'),
    (93,  8,  '2024-11-08', '2024-11-11', 'Completed'),
    (94,  7,  '2024-11-15', '2024-11-18', 'Completed'),
    (95,  4,  '2024-11-29', '2024-12-02', 'Completed'),  -- Black Friday
    (96,  9,  '2024-11-29', '2024-12-02', 'Completed'),  -- Black Friday
    (97,  6,  '2024-11-29', '2024-12-02', 'Completed'),  -- Black Friday
    (98,  1,  '2024-11-30', '2024-12-03', 'Completed'),  -- Black Friday weekend
    (99,  3,  '2024-11-30', '2024-12-03', 'Completed'),  -- Black Friday weekend
    (100, 10, '2024-12-03', '2024-12-06', 'Completed'),
    (101, 5,  '2024-12-07', '2024-12-10', 'Completed'),
    (102, 2,  '2024-12-10', '2024-12-13', 'Completed'),
    (103, 8,  '2024-12-13', '2024-12-16', 'Completed'),
    (104, 7,  '2024-12-16', '2024-12-19', 'Completed'),
    (105, 4,  '2024-12-18', '2024-12-21', 'Completed'),
    (106, 9,  '2024-12-19', '2024-12-22', 'Completed'),
    (107, 6,  '2024-12-20', '2024-12-23', 'Completed'),
    (108, 1,  '2024-12-21', '2024-12-24', 'Completed');


-- Order lines
-- Products available entire range (2022+): 15 (Bose QC45), 20 (Xbox Series X)
-- Products available from 2022-05-20+: 13 (Sony WH-1000XM5)
-- Products available from 2022-09-23+: 14 (AirPods Pro 2)
-- Products available from 2023-02-20+: 19 (LG OLED C3)
-- Products available from 2023-03-15+: 18 (Samsung Neo QLED)
-- Products available from 2023-04-01+: 17 (Sony Bravia)
-- Products available from 2023-08-11+: 8 (Galaxy Tab S9), 12 (Galaxy Watch 6)
-- Products available from 2023-09-22+: 1 (iPhone 15 Pro Max), 2 (iPhone 15), 10 (Apple Watch S9), 11 (Apple Watch Ultra 2)
-- Products available from 2023-10-19+: 16 (Bose QC Ultra)
-- Products available from 2023-11-07+: 5 (MacBook Pro 14 M3)
-- Products available from 2024-01-17+: 3 (Galaxy S24 Ultra), 4 (Galaxy S24)
-- Products available from 2024-03-08+: 6 (MacBook Air 15 M3)
-- Products available from 2024-04-09+: 7 (Surface Laptop 6)
-- Products available from 2024-05-15+: 9 (iPad Pro M4)

INSERT INTO OLTP_Tables.sales_order_line (order_line_id, order_id, product_id, quantity, unit_price, discount_pct, line_total) VALUES
-- 2022 orders (products 13, 14, 15, 20 only; 13 from Jun, 14 from Oct)
    (1,   1,  20, 1,  499.00, 0.00,  499.00),   -- Xbox
    (2,   2,  15, 1,  279.00, 0.00,  279.00),   -- Bose QC45
    (3,   3,  15, 1,  279.00, 0.00,  279.00),   -- Bose QC45
    (4,   4,  20, 1,  499.00, 0.00,  499.00),   -- Xbox
    (5,   5,  15, 1,  279.00, 0.00,  279.00),   -- Bose QC45
    (6,   6,  15, 2,  279.00, 0.00,  558.00),   -- Bose QC45 x2
    (7,   7,  20, 1,  499.00, 0.00,  499.00),   -- Xbox
    (8,   8,  13, 1,  349.00, 0.00,  349.00),   -- Sony XM5 (available from May)
    (9,   9,  15, 1,  279.00, 0.00,  279.00),   -- Bose QC45
    (10,  10, 13, 1,  349.00, 0.00,  349.00),   -- Sony XM5
    (11,  11, 20, 1,  499.00, 0.00,  499.00),   -- Xbox
    (12,  12, 13, 1,  349.00, 0.00,  349.00),   -- Sony XM5
    (13,  13, 15, 1,  279.00, 0.00,  279.00),   -- Bose QC45
    (14,  14, 14, 1,  249.00, 0.00,  249.00),   -- AirPods Pro 2 (available from Sep)
    (15,  15, 14, 1,  249.00, 0.00,  249.00),   -- AirPods Pro 2
    (16,  16, 13, 1,  349.00, 0.00,  349.00),   -- Sony XM5
    (17,  17, 15, 1,  279.00, 0.00,  279.00),   -- Bose QC45
    (18,  17, 20, 1,  499.00, 0.00,  499.00),   -- Xbox (multi-line order)
    (19,  18, 14, 1,  249.00, 0.00,  249.00),   -- AirPods Pro 2
    (20,  19, 20, 1,  499.00, 5.00,  474.05),   -- Xbox Black Friday
    (21,  19, 15, 1,  279.00, 5.00,  265.05),   -- Bose QC45 Black Friday
    (22,  20, 13, 1,  349.00, 5.00,  331.55),   -- Sony XM5 Black Friday
    (23,  21, 14, 1,  249.00, 5.00,  236.55),   -- AirPods Pro 2 Black Friday
    (24,  22, 20, 1,  499.00, 0.00,  499.00),   -- Xbox
    (25,  23, 14, 1,  249.00, 0.00,  249.00),   -- AirPods Pro 2
    (26,  24, 15, 1,  279.00, 0.00,  279.00),   -- Bose QC45
    (27,  25, 13, 1,  349.00, 0.00,  349.00),   -- Sony XM5
    (28,  26, 20, 1,  499.00, 0.00,  499.00),   -- Xbox
    (29,  27, 14, 1,  249.00, 0.00,  249.00),   -- AirPods Pro 2
    (30,  28, 15, 1,  279.00, 0.00,  279.00),   -- Bose QC45
    (31,  28, 14, 1,  249.00, 0.00,  249.00),   -- AirPods Pro 2 (multi-line)

-- 2023 orders
    (32,  29, 20, 1,  499.00, 0.00,  499.00),   -- Xbox
    (33,  30, 15, 1,  279.00, 0.00,  279.00),   -- Bose QC45
    (34,  31, 13, 1,  349.00, 0.00,  349.00),   -- Sony XM5
    (35,  32, 14, 1,  249.00, 0.00,  249.00),   -- AirPods Pro 2
    (36,  33, 19, 1, 1599.00, 0.00, 1599.00),   -- LG OLED (available Feb 2023)
    (37,  34, 15, 1,  279.00, 0.00,  279.00),   -- Bose QC45
    (38,  35, 18, 1, 1799.00, 0.00, 1799.00),   -- Samsung Neo QLED (available Mar 2023)
    (39,  36, 13, 1,  349.00, 0.00,  349.00),   -- Sony XM5
    (40,  37, 17, 1, 2999.00, 0.00, 2999.00),   -- Sony Bravia (available Apr 2023)
    (41,  38, 14, 1,  249.00, 0.00,  249.00),   -- AirPods Pro 2
    (42,  39, 20, 1,  499.00, 0.00,  499.00),   -- Xbox
    (43,  40, 19, 1, 1599.00, 0.00, 1599.00),   -- LG OLED
    (44,  41, 13, 1,  349.00, 0.00,  349.00),   -- Sony XM5
    (45,  42, 15, 1,  279.00, 0.00,  279.00),   -- Bose QC45
    (46,  43, 8,  1,  699.00, 0.00,  699.00),   -- Galaxy Tab S9 (available Aug 2023)
    (47,  44, 8,  1,  699.00, 0.00,  699.00),   -- Galaxy Tab S9 back to school
    (48,  45, 14, 1,  249.00, 0.00,  249.00),   -- AirPods Pro 2 back to school
    (49,  46, 12, 1,  399.00, 0.00,  399.00),   -- Galaxy Watch 6 (available Aug 2023)
    (50,  47, 1,  1, 1199.00, 0.00, 1199.00),   -- iPhone 15 Pro Max launch
    (51,  48, 2,  1,  799.00, 0.00,  799.00),   -- iPhone 15 launch
    (52,  49, 10, 1,  399.00, 0.00,  399.00),   -- Apple Watch S9 launch
    (53,  50, 1,  1, 1199.00, 0.00, 1199.00),   -- iPhone 15 Pro Max
    (54,  50, 10, 1,  399.00, 0.00,  399.00),   -- Apple Watch S9 (multi-line)
    (55,  51, 16, 1,  429.00, 0.00,  429.00),   -- Bose QC Ultra (available Oct 2023)
    (56,  52, 2,  1,  799.00, 0.00,  799.00),   -- iPhone 15
    (57,  53, 5,  1, 1999.00, 0.00, 1999.00),   -- MacBook Pro M3 (available Nov 2023)
    (58,  54, 1,  1, 1199.00, 10.00, 1079.10),  -- iPhone 15 Pro Max Black Friday
    (59,  54, 11, 1,  799.00, 10.00,  719.10),  -- Apple Watch Ultra 2 Black Friday
    (60,  55, 5,  1, 1999.00, 10.00, 1799.10),  -- MacBook Pro M3 Black Friday
    (61,  56, 19, 1, 1599.00, 10.00, 1439.10),  -- LG OLED Black Friday
    (62,  57, 2,  1,  799.00, 10.00,  719.10),  -- iPhone 15 Black Friday weekend
    (63,  58, 16, 1,  429.00, 10.00,  386.10),  -- Bose QC Ultra Black Friday weekend
    (64,  59, 13, 1,  349.00, 0.00,  349.00),   -- Sony XM5
    (65,  60, 8,  1,  699.00, 0.00,  699.00),   -- Galaxy Tab S9
    (66,  61, 18, 1, 1799.00, 0.00, 1799.00),   -- Samsung Neo QLED
    (67,  62, 1,  1, 1199.00, 0.00, 1199.00),   -- iPhone 15 Pro Max
    (68,  63, 14, 1,  249.00, 0.00,  249.00),   -- AirPods Pro 2
    (69,  64, 20, 1,  499.00, 0.00,  499.00),   -- Xbox
    (70,  65, 5,  1, 1999.00, 0.00, 1999.00),   -- MacBook Pro M3
    (71,  66, 2,  1,  799.00, 0.00,  799.00),   -- iPhone 15
    (72,  67, 10, 1,  399.00, 0.00,  399.00),   -- Apple Watch S9
    (73,  67, 16, 1,  429.00, 0.00,  429.00),   -- Bose QC Ultra (multi-line)

-- 2024 orders (full product range)
    (74,  68, 1,  1, 1199.00, 0.00, 1199.00),   -- iPhone 15 Pro Max
    (75,  69, 5,  1, 1999.00, 0.00, 1999.00),   -- MacBook Pro M3
    (76,  70, 20, 1,  499.00, 0.00,  499.00),   -- Xbox
    (77,  71, 16, 1,  429.00, 0.00,  429.00),   -- Bose QC Ultra Valentine's
    (78,  72, 14, 1,  249.00, 0.00,  249.00),   -- AirPods Pro 2 Valentine's
    (79,  73, 3,  1, 1299.00, 0.00, 1299.00),   -- Galaxy S24 Ultra (available Jan 2024)
    (80,  74, 4,  1,  799.00, 0.00,  799.00),   -- Galaxy S24
    (81,  75, 6,  1, 1299.00, 0.00, 1299.00),   -- MacBook Air M3 (available Mar 2024)
    (82,  76, 7,  1, 1299.00, 0.00, 1299.00),   -- Surface Laptop 6 (available Apr 2024)
    (83,  77, 13, 1,  349.00, 0.00,  349.00),   -- Sony XM5
    (84,  78, 9,  1, 1099.00, 0.00, 1099.00),   -- iPad Pro M4 launch
    (85,  79, 9,  1, 1099.00, 0.00, 1099.00),   -- iPad Pro M4 launch
    (86,  80, 3,  1, 1299.00, 0.00, 1299.00),   -- Galaxy S24 Ultra
    (87,  81, 2,  1,  799.00, 0.00,  799.00),   -- iPhone 15
    (88,  82, 15, 1,  279.00, 0.00,  279.00),   -- Bose QC45
    (89,  83, 12, 1,  399.00, 0.00,  399.00),   -- Galaxy Watch 6
    (90,  84, 17, 1, 2999.00, 0.00, 2999.00),   -- Sony Bravia
    (91,  85, 6,  1, 1299.00, 0.00, 1299.00),   -- MacBook Air M3 back to school
    (92,  85, 14, 1,  249.00, 0.00,  249.00),   -- AirPods Pro 2 (multi-line)
    (93,  86, 7,  1, 1299.00, 0.00, 1299.00),   -- Surface Laptop 6 back to school
    (94,  87, 9,  1, 1099.00, 0.00, 1099.00),   -- iPad Pro M4 back to school
    (95,  88, 4,  1,  799.00, 0.00,  799.00),   -- Galaxy S24
    (96,  89, 1,  1, 1199.00, 0.00, 1199.00),   -- iPhone 15 Pro Max
    (97,  90, 11, 1,  799.00, 0.00,  799.00),   -- Apple Watch Ultra 2
    (98,  91, 16, 1,  429.00, 0.00,  429.00),   -- Bose QC Ultra
    (99,  92, 19, 1, 1599.00, 0.00, 1599.00),   -- LG OLED
    (100, 93, 5,  1, 1999.00, 0.00, 1999.00),   -- MacBook Pro M3
    (101, 94, 3,  1, 1299.00, 0.00, 1299.00),   -- Galaxy S24 Ultra
    (102, 95, 1,  1, 1199.00, 15.00, 1019.15),  -- iPhone 15 Pro Max Black Friday
    (103, 95, 10, 1,  399.00, 15.00,  339.15),  -- Apple Watch S9 Black Friday (multi-line)
    (104, 96, 6,  1, 1299.00, 15.00, 1104.15),  -- MacBook Air M3 Black Friday
    (105, 97, 18, 1, 1799.00, 15.00, 1529.15),  -- Samsung Neo QLED Black Friday
    (106, 98, 5,  1, 1999.00, 15.00, 1699.15),  -- MacBook Pro M3 Black Friday weekend
    (107, 99, 9,  1, 1099.00, 15.00,  934.15),  -- iPad Pro M4 Black Friday weekend
    (108, 100,4,  1,  799.00, 0.00,  799.00),   -- Galaxy S24
    (109, 101,16, 1,  429.00, 0.00,  429.00),   -- Bose QC Ultra
    (110, 102,2,  1,  799.00, 0.00,  799.00),   -- iPhone 15
    (111, 103,17, 1, 2999.00, 0.00, 2999.00),   -- Sony Bravia
    (112, 104,7,  1, 1299.00, 0.00, 1299.00),   -- Surface Laptop 6
    (113, 105,12, 1,  399.00, 0.00,  399.00),   -- Galaxy Watch 6
    (114, 106,11, 1,  799.00, 0.00,  799.00),   -- Apple Watch Ultra 2
    (115, 107,9,  1, 1099.00, 0.00, 1099.00),   -- iPad Pro M4
    (116, 108,1,  1, 1199.00, 0.00, 1199.00),   -- iPhone 15 Pro Max
    (117, 108,16, 1,  429.00, 0.00,  429.00);   -- Bose QC Ultra (multi-line)