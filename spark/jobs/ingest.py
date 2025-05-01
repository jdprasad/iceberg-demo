#!/usr/bin/env python3

import argparse
from pyspark.sql import SparkSession
from pyspark.sql.functions import (
    regexp_extract, to_timestamp, when,
    to_date, col
)

def main(input_path, warehouse, table):
    # 1) SparkSession configured for Iceberg “demo” catalog on S3
    spark = SparkSession.builder \
        .appName("IngestJob") \
        .config("spark.sql.extensions", "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions") \
        .config("spark.sql.catalog.demo", "org.apache.iceberg.spark.SparkCatalog") \
        .config("spark.sql.catalog.demo.type", "hadoop") \
        .config("spark.sql.catalog.demo.warehouse", warehouse) \
        .getOrCreate()

    # 2) Read raw logs as text
    logs = spark.read.text(input_path)

    # 3) Parse out IP, timestamp string, and user agent
    pattern = (
        r'^(\d+\.\d+\.\d+\.\d+) - - '
        r'\[([^\]]+)\] "GET [^"]+" \d+ \d+ "[^"]+" "([^"]+)"'
    )
    df = logs.select(
        regexp_extract('value', pattern, 1).alias('ip_address'),
        regexp_extract('value', pattern, 2).alias('timestamp_str'),
        regexp_extract('value', pattern, 3).alias('user_agent')
    )

    # 4) Convert timestamp and derive device type
    df = df.withColumn(
        'event_timestamp',
        to_timestamp(col('timestamp_str'), 'dd/MMM/yyyy:HH:mm:ss Z')
    ).withColumn(
        'device',
        when(col('user_agent').rlike('(?i)mobile'), 'mobile')
        .when(col('user_agent').rlike('(?i)tablet|ipad'), 'tablet')
        .otherwise('desktop')
    )

    # 5) Extract event_date (as DATE) for partitioning
    df = df.withColumn('event_date', to_date(col('event_timestamp')))

    # 6) Register table DDL (idempotent)
    qualified = f"demo.{table}"
    location = f"{warehouse.rstrip('/')}/{table}"
    spark.sql(f"""
        CREATE TABLE IF NOT EXISTS {qualified} (
          ip_address      STRING,
          event_timestamp TIMESTAMP,
          device          STRING,
          event_date      DATE
        )
        USING iceberg
        PARTITIONED BY (event_date)
        LOCATION '{location}'
    """)

    # 7) Only select the columns that the table expects
    to_write = df.select('ip_address', 'event_timestamp', 'device', 'event_date')

    # 8) Append new data
    to_write.writeTo(qualified).append()

    spark.stop()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Ingest raw logs into Iceberg"
    )
    parser.add_argument(
        "--input", required=True,
        help="S3A path to raw log files"
    )
    parser.add_argument(
        "--warehouse", required=True,
        help="Iceberg warehouse S3 path"
    )
    parser.add_argument(
        "--table", required=True,
        help="Table name within the demo catalog (e.g. logs)"
    )
    args = parser.parse_args()
    main(args.input, args.warehouse, args.table)
