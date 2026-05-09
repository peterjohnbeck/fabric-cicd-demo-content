# Fabric notebook source



import pyodbc
import struct
import requests

# -----------------------------------------------------------------------
# Dynamically resolve the workspace SQL endpoint at runtime.
# This eliminates hardcoded environment-specific values from the notebook,
# making it deployable across DEV and PRD without any substitution needed.
#
# notebookutils.fabric.getWorkspaceId() returns the GUID of the workspace
# this notebook is currently running in — DEV or PRD automatically.
#
# The Fabric REST API List Warehouses endpoint returns the connectionString
# for every warehouse in the workspace. We look up Source_WH and Target_WH
# by display name.
# -----------------------------------------------------------------------

def get_workspace_endpoint(warehouse_name: str) -> str:
    """
    Retrieves the SQL connection string for a named warehouse
    in the current workspace using the Fabric REST API.
    Authentication uses the notebook's current user token.
    """
    workspace_id = notebookutils.runtime.context.get("currentWorkspaceId")
    token = notebookutils.credentials.getToken("https://api.fabric.microsoft.com")

    url = f"https://api.fabric.microsoft.com/v1/workspaces/{workspace_id}/warehouses"
    headers = {"Authorization": f"Bearer {token}"}

    response = requests.get(url, headers=headers, timeout=30)
    response.raise_for_status()

    warehouses = response.json().get("value", [])
    for wh in warehouses:
        if wh.get("displayName") == warehouse_name:
            endpoint = wh.get("properties", {}).get("connectionString", "")
            if not endpoint:
                raise ValueError(f"Warehouse '{warehouse_name}' found but has no connectionString")
            return endpoint

    raise ValueError(
        f"Warehouse '{warehouse_name}' not found in workspace {workspace_id}. "
        f"Available: {[w['displayName'] for w in warehouses]}"
    )

print("Resolving warehouse endpoints...")
SOURCE_WH_ENDPOINT = get_workspace_endpoint("Source_WH")
TARGET_WH_ENDPOINT = get_workspace_endpoint("Target_WH")
SOURCE_DB = "Source_WH"
TARGET_DB = "Target_WH"
print(f"  Source: {SOURCE_WH_ENDPOINT}")
print(f"  Target: {TARGET_WH_ENDPOINT}")


def get_connection(endpoint, database):
    token = notebookutils.credentials.getToken("https://database.windows.net/")
    token_bytes = token.encode("UTF-16-LE")
    token_struct = struct.pack(f'<I{len(token_bytes)}s', len(token_bytes), token_bytes)
    conn_str = (
        f"Driver={{ODBC Driver 18 for SQL Server}};"
        f"Server={endpoint},1433;"
        f"Database={database};"
        f"Encrypt=Yes;"
        f"TrustServerCertificate=No;"
    )
    conn = pyodbc.connect(conn_str, attrs_before={1256: token_struct})
    conn.autocommit = True
    return conn

target = get_connection(TARGET_WH_ENDPOINT, TARGET_DB)
source = get_connection(SOURCE_WH_ENDPOINT, SOURCE_DB)
tc = target.cursor()
sc = source.cursor()

# -----------------------------------------------------------------------
# TRUNCATE (facts first, then dims)
# -----------------------------------------------------------------------
print("Dropping foreign keys...")
drop_fks = [
    "ALTER TABLE REPORTING.fact_sales DROP CONSTRAINT FK_fact_sales_order_date",
    "ALTER TABLE REPORTING.fact_sales DROP CONSTRAINT FK_fact_sales_ship_date",
    "ALTER TABLE REPORTING.fact_sales DROP CONSTRAINT FK_fact_sales_customer",
    "ALTER TABLE REPORTING.fact_sales DROP CONSTRAINT FK_fact_sales_product",
    "ALTER TABLE REPORTING.fact_sales DROP CONSTRAINT FK_fact_sales_geography",
    "ALTER TABLE REPORTING.fact_sales DROP CONSTRAINT FK_fact_sales_order_status",
    "ALTER TABLE REPORTING.fact_sales_monthly_snapshot DROP CONSTRAINT FK_fsms_snapshot_date",
    "ALTER TABLE REPORTING.fact_sales_monthly_snapshot DROP CONSTRAINT FK_fsms_customer",
    "ALTER TABLE REPORTING.fact_sales_monthly_snapshot DROP CONSTRAINT FK_fsms_product",
    "ALTER TABLE REPORTING.fact_sales_monthly_snapshot DROP CONSTRAINT FK_fsms_geography",
]
for stmt in drop_fks:
    tc.execute(stmt)
    print(f"  Done: {stmt}")

print("Truncating...")
for t in [
    "REPORTING.fact_sales_monthly_snapshot",
    "REPORTING.fact_sales",
    "REPORTING.dim_order_status",
    "REPORTING.dim_geography",
    "REPORTING.dim_product",
    "REPORTING.dim_customer",
    "REPORTING.dim_date",
]:
    tc.execute(f"TRUNCATE TABLE {t}")
    print(f"  Truncated {t}")

print("Recreating foreign keys...")
add_fks = [
    "ALTER TABLE REPORTING.fact_sales ADD CONSTRAINT FK_fact_sales_order_date FOREIGN KEY (order_date_key) REFERENCES REPORTING.dim_date (date_key) NOT ENFORCED",
    "ALTER TABLE REPORTING.fact_sales ADD CONSTRAINT FK_fact_sales_ship_date FOREIGN KEY (ship_date_key) REFERENCES REPORTING.dim_date (date_key) NOT ENFORCED",
    "ALTER TABLE REPORTING.fact_sales ADD CONSTRAINT FK_fact_sales_customer FOREIGN KEY (customer_key) REFERENCES REPORTING.dim_customer (customer_key) NOT ENFORCED",
    "ALTER TABLE REPORTING.fact_sales ADD CONSTRAINT FK_fact_sales_product FOREIGN KEY (product_key) REFERENCES REPORTING.dim_product (product_key) NOT ENFORCED",
    "ALTER TABLE REPORTING.fact_sales ADD CONSTRAINT FK_fact_sales_geography FOREIGN KEY (geography_key) REFERENCES REPORTING.dim_geography (geography_key) NOT ENFORCED",
    "ALTER TABLE REPORTING.fact_sales ADD CONSTRAINT FK_fact_sales_order_status FOREIGN KEY (order_status_key) REFERENCES REPORTING.dim_order_status (order_status_key) NOT ENFORCED",
    "ALTER TABLE REPORTING.fact_sales_monthly_snapshot ADD CONSTRAINT FK_fsms_snapshot_date FOREIGN KEY (snapshot_date_key) REFERENCES REPORTING.dim_date (date_key) NOT ENFORCED",
    "ALTER TABLE REPORTING.fact_sales_monthly_snapshot ADD CONSTRAINT FK_fsms_customer FOREIGN KEY (customer_key) REFERENCES REPORTING.dim_customer (customer_key) NOT ENFORCED",
    "ALTER TABLE REPORTING.fact_sales_monthly_snapshot ADD CONSTRAINT FK_fsms_product FOREIGN KEY (product_key) REFERENCES REPORTING.dim_product (product_key) NOT ENFORCED",
    "ALTER TABLE REPORTING.fact_sales_monthly_snapshot ADD CONSTRAINT FK_fsms_geography FOREIGN KEY (geography_key) REFERENCES REPORTING.dim_geography (geography_key) NOT ENFORCED",
]
for stmt in add_fks:
    tc.execute(stmt)
    print(f"  Done: {stmt}")

# -----------------------------------------------------------------------
# HELPER: read from source, write to target
# -----------------------------------------------------------------------
def load(label, read_cursor, write_cursor, select_sql, insert_sql):
    print(f"Loading {label}...")
    read_cursor.execute(select_sql)
    rows = read_cursor.fetchall()
    write_cursor.fast_executemany = True
    placeholders = ",".join(["?" for _ in range(len(rows[0]))])
    write_cursor.executemany(f"{insert_sql} VALUES ({placeholders})", [list(r) for r in rows])
    print(f"  {len(rows)} rows written")

# -----------------------------------------------------------------------
# dim_date  (generated entirely in Python, no source query needed)
# -----------------------------------------------------------------------
print("Loading dim_date...")
from datetime import date, timedelta

def build_dim_date_sql(start, end):
    rows = []
    d = start
    while d <= end:
        dow        = d.isoweekday()
        is_weekend = 1 if dow >= 6 else 0
        q          = (d.month - 1) // 3 + 1
        yday       = d.timetuple().tm_yday
        week       = int(d.strftime("%W"))
        rows.append(
            f"({d.strftime('%Y%m%d')}, '{d}', {dow}, '{d.strftime('%A')}', "
            f"{d.day}, {yday}, {week}, {d.month}, '{d.strftime('%B')}', "
            f"'{d.strftime('%b')}', {q}, 'Q{q}', {d.year}, "
            f"{is_weekend}, 0, {d.year}, {q}, {d.month})"
        )
        d += timedelta(days=1)
    return rows

value_rows = build_dim_date_sql(date(2022, 1, 1), date(2024, 12, 31))

batch_size = 500
batches = [value_rows[i:i+batch_size] for i in range(0, len(value_rows), batch_size)]
for i, batch in enumerate(batches):
    sql = "INSERT INTO REPORTING.dim_date VALUES " + ",".join(batch)
    tc.execute(sql)
print(f"  {len(value_rows)} rows written in {len(batches)} batches")

# -----------------------------------------------------------------------
# dim_customer
# -----------------------------------------------------------------------
load("dim_customer", sc, tc,
"""
SELECT
    ROW_NUMBER() OVER (ORDER BY c.customer_id),
    c.customer_id,
    c.first_name,
    c.last_name,
    CONCAT(c.first_name, ' ', c.last_name),
    c.email,
    c.phone,
    c.date_of_birth,
    CASE
        WHEN DATEDIFF(YEAR, c.date_of_birth, GETDATE()) < 25 THEN '18-24'
        WHEN DATEDIFF(YEAR, c.date_of_birth, GETDATE()) < 35 THEN '25-34'
        WHEN DATEDIFF(YEAR, c.date_of_birth, GETDATE()) < 45 THEN '35-44'
        WHEN DATEDIFF(YEAR, c.date_of_birth, GETDATE()) < 55 THEN '45-54'
        ELSE '55+'
    END,
    ci.city_name,
    s.state_name,
    s.state_code,
    co.country_name,
    co.country_code,
    a.postal_code,
    CAST('2022-01-01' AS DATE),
    NULL,
    CAST(1 AS SMALLINT)
FROM       OLTP_Tables.customer  c
INNER JOIN OLTP_Tables.address   a  ON a.address_id  = c.address_id
INNER JOIN OLTP_Tables.city      ci ON ci.city_id    = a.city_id
INNER JOIN OLTP_Tables.state     s  ON s.state_id    = ci.state_id
INNER JOIN OLTP_Tables.country   co ON co.country_id = s.country_id
""",
"INSERT INTO REPORTING.dim_customer")

# -----------------------------------------------------------------------
# dim_product
# -----------------------------------------------------------------------
load("dim_product", sc, tc,
"""
SELECT
    ROW_NUMBER() OVER (ORDER BY p.product_id),
    p.product_id,
    p.sku,
    p.product_name,
    b.brand_name,
    co.country_name,
    pc.category_name,
    ps.status_name,
    u.uom_code,
    p.unit_price,
    p.weight_kg,
    p.warranty_months,
    p.introduced_date,
    CAST('2022-01-01' AS DATE),
    NULL,
    CAST(1 AS SMALLINT)
FROM       OLTP_Tables.product          p
INNER JOIN OLTP_Tables.brand            b  ON b.brand_id     = p.brand_id
INNER JOIN OLTP_Tables.country          co ON co.country_id  = b.country_id
INNER JOIN OLTP_Tables.product_category pc ON pc.category_id = p.category_id
INNER JOIN OLTP_Tables.product_status   ps ON ps.status_id   = p.status_id
INNER JOIN OLTP_Tables.unit_of_measure  u  ON u.uom_id       = p.uom_id
""",
"INSERT INTO REPORTING.dim_product")

# -----------------------------------------------------------------------
# dim_geography
# -----------------------------------------------------------------------
load("dim_geography", sc, tc,
"""
SELECT
    ROW_NUMBER() OVER (ORDER BY co.country_name, s.state_name, ci.city_name),
    ci.city_name,
    s.state_name,
    s.state_code,
    co.country_name,
    co.country_code
FROM       OLTP_Tables.city    ci
INNER JOIN OLTP_Tables.state   s  ON s.state_id    = ci.state_id
INNER JOIN OLTP_Tables.country co ON co.country_id = s.country_id
""",
"INSERT INTO REPORTING.dim_geography")

# -----------------------------------------------------------------------
# dim_order_status
# -----------------------------------------------------------------------
load("dim_order_status", sc, tc,
"""
SELECT
    ROW_NUMBER() OVER (ORDER BY order_status),
    order_status
FROM (SELECT DISTINCT order_status FROM OLTP_Tables.sales_order) s
""",
"INSERT INTO REPORTING.dim_order_status")

# -----------------------------------------------------------------------
# fact_sales
# -----------------------------------------------------------------------
load("fact_sales", sc, tc,
"""
SELECT
    ROW_NUMBER() OVER (ORDER BY sol.order_line_id),
    sol.order_line_id,
    so.order_id,
    CAST(FORMAT(so.order_date, 'yyyyMMdd') AS INT),
    CASE WHEN so.ship_date IS NOT NULL
         THEN CAST(FORMAT(so.ship_date, 'yyyyMMdd') AS INT) END,
    dc.customer_key,
    dp.product_key,
    dg.geography_key,
    dos.order_status_key,
    sol.quantity,
    sol.unit_price,
    sol.discount_pct,
    ROUND(sol.unit_price * sol.quantity * sol.discount_pct / 100, 2),
    ROUND(sol.unit_price * sol.quantity, 2),
    sol.line_total,
    NULL,
    NULL,
    CASE WHEN so.ship_date IS NOT NULL
         THEN CAST(DATEDIFF(DAY, so.order_date, so.ship_date) AS SMALLINT) END
FROM       OLTP_Tables.sales_order_line  sol
INNER JOIN OLTP_Tables.sales_order       so  ON so.order_id    = sol.order_id
INNER JOIN OLTP_Tables.customer          c   ON c.customer_id  = so.customer_id
INNER JOIN OLTP_Tables.address           a   ON a.address_id   = c.address_id
INNER JOIN OLTP_Tables.city              ci  ON ci.city_id     = a.city_id
INNER JOIN OLTP_Tables.state             s   ON s.state_id     = ci.state_id
INNER JOIN OLTP_Tables.country           co  ON co.country_id  = s.country_id
INNER JOIN TARGET_WH.REPORTING.dim_customer   dc  ON dc.customer_id  = c.customer_id  AND dc.is_current = 1
INNER JOIN TARGET_WH.REPORTING.dim_product    dp  ON dp.product_id   = sol.product_id AND dp.is_current = 1
INNER JOIN TARGET_WH.REPORTING.dim_geography  dg  ON dg.city         = ci.city_name
                                                  AND dg.state_code  = s.state_code
                                                  AND dg.country_code= co.country_code
INNER JOIN TARGET_WH.REPORTING.dim_order_status dos ON dos.order_status = so.order_status
""",
"INSERT INTO REPORTING.fact_sales")

# -----------------------------------------------------------------------
# fact_sales_monthly_snapshot
# -----------------------------------------------------------------------
load("fact_sales_monthly_snapshot", sc, tc,
"""
SELECT
    ROW_NUMBER() OVER (ORDER BY customer_key, product_key, geography_key, year_number, month_number),
    CAST(FORMAT(EOMONTH(DATEFROMPARTS(year_number, month_number, 1)), 'yyyyMMdd') AS INT),
    customer_key,
    product_key,
    geography_key,
    order_count,
    quantity_sold,
    gross_sales_amount,
    discount_amount,
    net_sales_amount,
    NULL,
    SUM(order_count)      OVER (PARTITION BY customer_key, product_key, geography_key, year_number ORDER BY month_number ROWS UNBOUNDED PRECEDING),
    SUM(quantity_sold)    OVER (PARTITION BY customer_key, product_key, geography_key, year_number ORDER BY month_number ROWS UNBOUNDED PRECEDING),
    SUM(net_sales_amount) OVER (PARTITION BY customer_key, product_key, geography_key, year_number ORDER BY month_number ROWS UNBOUNDED PRECEDING)
FROM (
    SELECT
        dc.customer_key,
        dp.product_key,
        dg.geography_key,
        YEAR(so.order_date)                                               AS year_number,
        MONTH(so.order_date)                                              AS month_number,
        COUNT(sol.order_line_id)                                          AS order_count,
        SUM(sol.quantity)                                                 AS quantity_sold,
        ROUND(SUM(sol.unit_price * sol.quantity), 2)                      AS gross_sales_amount,
        ROUND(SUM(sol.unit_price * sol.quantity * sol.discount_pct / 100), 2) AS discount_amount,
        ROUND(SUM(sol.line_total), 2)                                     AS net_sales_amount
    FROM       OLTP_Tables.sales_order_line  sol
    INNER JOIN OLTP_Tables.sales_order       so  ON so.order_id    = sol.order_id
    INNER JOIN OLTP_Tables.customer          c   ON c.customer_id  = so.customer_id
    INNER JOIN OLTP_Tables.address           a   ON a.address_id   = c.address_id
    INNER JOIN OLTP_Tables.city              ci  ON ci.city_id     = a.city_id
    INNER JOIN OLTP_Tables.state             s   ON s.state_id     = ci.state_id
    INNER JOIN OLTP_Tables.country           co  ON co.country_id  = s.country_id
    INNER JOIN TARGET_WH.REPORTING.dim_customer   dc  ON dc.customer_id  = c.customer_id  AND dc.is_current = 1
    INNER JOIN TARGET_WH.REPORTING.dim_product    dp  ON dp.product_id   = sol.product_id AND dp.is_current = 1
    INNER JOIN TARGET_WH.REPORTING.dim_geography  dg  ON dg.city         = ci.city_name
                                                      AND dg.state_code  = s.state_code
                                                      AND dg.country_code= co.country_code
    GROUP BY
        dc.customer_key, dp.product_key, dg.geography_key,
        YEAR(so.order_date), MONTH(so.order_date)
) monthly
""",
"INSERT INTO REPORTING.fact_sales_monthly_snapshot")

# -----------------------------------------------------------------------
# Cleanup
# -----------------------------------------------------------------------
sc.close()
tc.close()
source.close()
target.close()
print("Done.")


# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }