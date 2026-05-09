-- DIMENSIONS

CREATE SCHEMA REPORTING;

CREATE TABLE REPORTING.dim_date (
    date_key        INT          NOT NULL,  -- YYYYMMDD surrogate
    full_date       DATE         NOT NULL,
    day_of_week     SMALLINT     NOT NULL,  -- 1=Monday ... 7=Sunday
    day_name        VARCHAR(10)  NOT NULL,
    day_of_month    SMALLINT     NOT NULL,
    day_of_year     SMALLINT     NOT NULL,
    week_of_year    SMALLINT     NOT NULL,
    month_number    SMALLINT     NOT NULL,
    month_name      VARCHAR(10)  NOT NULL,
    month_short     CHAR(3)      NOT NULL,
    quarter_number  SMALLINT     NOT NULL,
    quarter_name    CHAR(2)      NOT NULL,  -- Q1, Q2, Q3, Q4
    year_number     SMALLINT     NOT NULL,
    is_weekend      SMALLINT     NOT NULL,  -- 1/0
    is_holiday      SMALLINT     NOT NULL,  -- 1/0
    fiscal_year     SMALLINT     NOT NULL,
    fiscal_quarter  SMALLINT     NOT NULL,
    fiscal_month    SMALLINT     NOT NULL
);

ALTER TABLE REPORTING.dim_date
    ADD CONSTRAINT PK_dim_date PRIMARY KEY NONCLUSTERED (date_key) NOT ENFORCED;

ALTER TABLE REPORTING.dim_date
    ADD CONSTRAINT UQ_dim_date_full_date UNIQUE NONCLUSTERED (full_date) NOT ENFORCED;


CREATE TABLE REPORTING.dim_customer (
    customer_key    INT          NOT NULL,  -- surrogate key
    customer_id     INT          NOT NULL,  -- source natural key
    first_name      VARCHAR(100) NOT NULL,
    last_name       VARCHAR(100) NOT NULL,
    full_name       VARCHAR(200) NOT NULL,
    email           VARCHAR(255) NOT NULL,
    phone           VARCHAR(30),
    date_of_birth   DATE,
    age_band        VARCHAR(20),            -- e.g. 18-24, 25-34 etc.
    city            VARCHAR(100) NOT NULL,
    state           VARCHAR(100) NOT NULL,
    state_code      CHAR(2)      NOT NULL,
    country         VARCHAR(100) NOT NULL,
    country_code    CHAR(2)      NOT NULL,
    postal_code     VARCHAR(20)  NOT NULL,
    -- SCD Type 2 columns
    effective_from  DATE         NOT NULL,
    effective_to    DATE,                   -- NULL = current record
    is_current      SMALLINT     NOT NULL   -- 1/0
);

ALTER TABLE REPORTING.dim_customer
    ADD CONSTRAINT PK_dim_customer PRIMARY KEY NONCLUSTERED (customer_key) NOT ENFORCED;


CREATE TABLE REPORTING.dim_product (
    product_key         INT             NOT NULL,  -- surrogate key
    product_id          INT             NOT NULL,  -- source natural key
    sku                 VARCHAR(50)     NOT NULL,
    product_name        VARCHAR(200)    NOT NULL,
    brand               VARCHAR(100)    NOT NULL,
    brand_country       VARCHAR(100)    NOT NULL,
    category            VARCHAR(100)    NOT NULL,
    product_status      VARCHAR(50)     NOT NULL,
    unit_of_measure     VARCHAR(20)     NOT NULL,
    current_unit_price  DECIMAL(10, 2)  NOT NULL,
    weight_kg           DECIMAL(8, 3),
    warranty_months     SMALLINT,
    introduced_date     DATE,
    -- SCD Type 2 columns
    effective_from      DATE            NOT NULL,
    effective_to        DATE,                       -- NULL = current record
    is_current          SMALLINT        NOT NULL    -- 1/0
);

ALTER TABLE REPORTING.dim_product
    ADD CONSTRAINT PK_dim_product PRIMARY KEY NONCLUSTERED (product_key) NOT ENFORCED;


CREATE TABLE REPORTING.dim_geography (
    geography_key   INT          NOT NULL,  -- surrogate key
    city            VARCHAR(100) NOT NULL,
    state           VARCHAR(100) NOT NULL,
    state_code      CHAR(2)      NOT NULL,
    country         VARCHAR(100) NOT NULL,
    country_code    CHAR(2)      NOT NULL
);

ALTER TABLE REPORTING.dim_geography
    ADD CONSTRAINT PK_dim_geography PRIMARY KEY NONCLUSTERED (geography_key) NOT ENFORCED;


CREATE TABLE REPORTING.dim_order_status (
    order_status_key  INT         NOT NULL,
    order_status      VARCHAR(20) NOT NULL
);

ALTER TABLE REPORTING.dim_order_status
    ADD CONSTRAINT PK_dim_order_status PRIMARY KEY NONCLUSTERED (order_status_key) NOT ENFORCED;

ALTER TABLE REPORTING.dim_order_status
    ADD CONSTRAINT UQ_dim_order_status UNIQUE NONCLUSTERED (order_status) NOT ENFORCED;


-- FACTS

CREATE TABLE REPORTING.fact_sales (
    sales_key           INT             NOT NULL,  -- surrogate key
    order_line_id       INT             NOT NULL,  -- source natural key
    order_id            INT             NOT NULL,
    order_date_key      INT             NOT NULL,  -- FK to dim_date
    ship_date_key       INT,                       -- FK to dim_date; NULL if not yet shipped
    customer_key        INT             NOT NULL,  -- FK to dim_customer
    product_key         INT             NOT NULL,  -- FK to dim_product
    geography_key       INT             NOT NULL,  -- FK to dim_geography
    order_status_key    INT             NOT NULL,  -- FK to dim_order_status
    -- measures
    quantity            SMALLINT        NOT NULL,
    unit_price          DECIMAL(10, 2)  NOT NULL,
    discount_pct        DECIMAL(5, 2)   NOT NULL,
    discount_amount     DECIMAL(10, 2)  NOT NULL,
    gross_sales_amount  DECIMAL(10, 2)  NOT NULL,  -- quantity * unit_price
    net_sales_amount    DECIMAL(10, 2)  NOT NULL,  -- gross_sales - discount
    cost_amount         DECIMAL(10, 2),            -- for margin if cost data available
    gross_margin_amount DECIMAL(10, 2),
    days_to_ship        SMALLINT                   -- ship_date - order_date
);

ALTER TABLE REPORTING.fact_sales
    ADD CONSTRAINT PK_fact_sales PRIMARY KEY NONCLUSTERED (sales_key) NOT ENFORCED;

ALTER TABLE REPORTING.fact_sales
    ADD CONSTRAINT FK_fact_sales_order_date FOREIGN KEY (order_date_key)
    REFERENCES REPORTING.dim_date (date_key) NOT ENFORCED;

ALTER TABLE REPORTING.fact_sales
    ADD CONSTRAINT FK_fact_sales_ship_date FOREIGN KEY (ship_date_key)
    REFERENCES REPORTING.dim_date (date_key) NOT ENFORCED;

ALTER TABLE REPORTING.fact_sales
    ADD CONSTRAINT FK_fact_sales_customer FOREIGN KEY (customer_key)
    REFERENCES REPORTING.dim_customer (customer_key) NOT ENFORCED;

ALTER TABLE REPORTING.fact_sales
    ADD CONSTRAINT FK_fact_sales_product FOREIGN KEY (product_key)
    REFERENCES REPORTING.dim_product (product_key) NOT ENFORCED;

ALTER TABLE REPORTING.fact_sales
    ADD CONSTRAINT FK_fact_sales_geography FOREIGN KEY (geography_key)
    REFERENCES REPORTING.dim_geography (geography_key) NOT ENFORCED;

ALTER TABLE REPORTING.fact_sales
    ADD CONSTRAINT FK_fact_sales_order_status FOREIGN KEY (order_status_key)
    REFERENCES REPORTING.dim_order_status (order_status_key) NOT ENFORCED;


CREATE TABLE REPORTING.fact_sales_monthly_snapshot (
    snapshot_key        INT             NOT NULL,  -- surrogate key
    snapshot_date_key   INT             NOT NULL,  -- FK to dim_date; last day of month
    customer_key        INT             NOT NULL,  -- FK to dim_customer
    product_key         INT             NOT NULL,  -- FK to dim_product
    geography_key       INT             NOT NULL,  -- FK to dim_geography
    -- period measures
    order_count         INT             NOT NULL,
    quantity_sold       INT             NOT NULL,
    gross_sales_amount  DECIMAL(12, 2)  NOT NULL,
    discount_amount     DECIMAL(12, 2)  NOT NULL,
    net_sales_amount    DECIMAL(12, 2)  NOT NULL,
    gross_margin_amount DECIMAL(12, 2),
    -- cumulative YTD measures
    ytd_order_count     INT             NOT NULL,
    ytd_quantity_sold   INT             NOT NULL,
    ytd_net_sales       DECIMAL(12, 2)  NOT NULL
);

ALTER TABLE REPORTING.fact_sales_monthly_snapshot
    ADD CONSTRAINT PK_fact_sales_monthly_snapshot PRIMARY KEY NONCLUSTERED (snapshot_key) NOT ENFORCED;

ALTER TABLE REPORTING.fact_sales_monthly_snapshot
    ADD CONSTRAINT FK_fsms_snapshot_date FOREIGN KEY (snapshot_date_key)
    REFERENCES REPORTING.dim_date (date_key) NOT ENFORCED;

ALTER TABLE REPORTING.fact_sales_monthly_snapshot
    ADD CONSTRAINT FK_fsms_customer FOREIGN KEY (customer_key)
    REFERENCES REPORTING.dim_customer (customer_key) NOT ENFORCED;

ALTER TABLE REPORTING.fact_sales_monthly_snapshot
    ADD CONSTRAINT FK_fsms_product FOREIGN KEY (product_key)
    REFERENCES REPORTING.dim_product (product_key) NOT ENFORCED;

ALTER TABLE REPORTING.fact_sales_monthly_snapshot
    ADD CONSTRAINT FK_fsms_geography FOREIGN KEY (geography_key)
    REFERENCES REPORTING.dim_geography (geography_key) NOT ENFORCED;