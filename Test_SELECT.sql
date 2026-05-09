SELECT TOP 100
    f.sales_key,
    f.order_id,
    f.order_line_id,
    dd_ord.full_date                AS order_date,
    dd_shp.full_date                AS ship_date,
    f.days_to_ship,
    dc.full_name                    AS customer_name,
    dc.city                         AS customer_city,
    dc.state                        AS customer_state,
    dc.country                      AS customer_country,
    dp.product_name,
    dp.brand,
    dp.category,
    dg.city                         AS ship_city,
    dg.state                        AS ship_state,
    dg.country                      AS ship_country,
    dos.order_status,
    f.quantity,
    f.unit_price,
    f.discount_pct,
    f.discount_amount,
    f.gross_sales_amount,
    f.net_sales_amount
FROM       REPORTING.fact_sales                 f
INNER JOIN REPORTING.dim_date                   dd_ord ON dd_ord.date_key      = f.order_date_key
LEFT  JOIN REPORTING.dim_date                   dd_shp ON dd_shp.date_key      = f.ship_date_key
INNER JOIN REPORTING.dim_customer               dc     ON dc.customer_key      = f.customer_key
INNER JOIN REPORTING.dim_product                dp     ON dp.product_key       = f.product_key
INNER JOIN REPORTING.dim_geography              dg     ON dg.geography_key     = f.geography_key
INNER JOIN REPORTING.dim_order_status           dos    ON dos.order_status_key = f.order_status_key
ORDER BY f.order_id, f.order_line_id