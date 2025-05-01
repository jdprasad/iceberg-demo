#!/usr/bin/env python3

from pyspark.sql import SparkSession

def main(sql_file_path: str):
    spark = (
        SparkSession.builder
        .appName("AnalyticsJob")
        .config("spark.sql.extensions", "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions")
        .config("spark.sql.catalog.demo", "org.apache.iceberg.spark.SparkCatalog")
        .config("spark.sql.catalog.demo.type", "hadoop")
        .config("spark.sql.catalog.demo.warehouse", "s3a://iceberg-demo-warehouse-demo/")
        .getOrCreate()
    )

    # Read and execute each SQL statement
    with open(sql_file_path, "r") as f:
        statements = [s.strip() for s in f.read().split(";") if s.strip()]
    for stmt in statements:
        print(f"▶️ Running SQL:\n{stmt}\n")
        spark.sql(stmt)

    spark.stop()

if __name__ == "__main__":
    import sys
    if len(sys.argv) != 2:
        print("Usage: python run_sql.py <path_to_analytics.sql>")
        sys.exit(1)
    main(sys.argv[1])

