-- =====================================================================
-- Analytics Tables in Iceberg (using the 'demo' catalog)
-- =====================================================================

-- 0. Ensure analytics namespace
CREATE NAMESPACE IF NOT EXISTS demo.analytics;

--------------------------------------------------------------------------------
-- 1. Daily Top-5 IP Addresses
--------------------------------------------------------------------------------
CREATE OR REPLACE TABLE demo.analytics.daily_top5_ip
USING iceberg
PARTITIONED BY (event_date)
AS
SELECT event_date, ip_address, cnt
FROM (
  SELECT
    event_date,
    ip_address,
    COUNT(*) AS cnt,
    ROW_NUMBER() OVER (
      PARTITION BY event_date
      ORDER BY COUNT(*) DESC
    ) AS rn
  FROM demo.logs
  GROUP BY event_date, ip_address
) t
WHERE rn <= 5;

--------------------------------------------------------------------------------
-- 2. Weekly Top-5 IP Addresses
--------------------------------------------------------------------------------
CREATE OR REPLACE TABLE demo.analytics.weekly_top5_ip
USING iceberg
PARTITIONED BY (week_start)
AS
SELECT week_start, ip_address, cnt
FROM (
  SELECT
    date_trunc('week', event_date) AS week_start,
    ip_address,
    COUNT(*)     AS cnt,
    ROW_NUMBER() OVER (
      PARTITION BY date_trunc('week', event_date)
      ORDER BY COUNT(*) DESC
    ) AS rn
  FROM demo.logs
  GROUP BY date_trunc('week', event_date), ip_address
) t
WHERE rn <= 5;

--------------------------------------------------------------------------------
-- 3. Daily Top-5 Devices
--------------------------------------------------------------------------------
CREATE OR REPLACE TABLE demo.analytics.daily_top5_device
USING iceberg
PARTITIONED BY (event_date)
AS
SELECT event_date, device, cnt
FROM (
  SELECT
    event_date,
    device,
    COUNT(*)     AS cnt,
    ROW_NUMBER() OVER (
      PARTITION BY event_date
      ORDER BY COUNT(*) DESC
    ) AS rn
  FROM demo.logs
  GROUP BY event_date, device
) t
WHERE rn <= 5;

--------------------------------------------------------------------------------
-- 4. Weekly Top-5 Devices
--------------------------------------------------------------------------------
CREATE OR REPLACE TABLE demo.analytics.weekly_top5_device
USING iceberg
PARTITIONED BY (week_start)
AS
SELECT week_start, device, cnt
FROM (
  SELECT
    date_trunc('week', event_date) AS week_start,
    device,
    COUNT(*)     AS cnt,
    ROW_NUMBER() OVER (
      PARTITION BY date_trunc('week', event_date)
      ORDER BY COUNT(*) DESC
    ) AS rn
  FROM demo.logs
  GROUP BY date_trunc('week', event_date), device
) t
WHERE rn <= 5;
