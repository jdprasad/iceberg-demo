# Iceberg Demo

This repository demonstrates a data pipeline for processing simulated web access logs using **Apache Spark** and **Apache Iceberg** on **Amazon EKS**. It ingests raw logs from S3, transforms and stores them in Iceberg format, and runs analytics to generate top-5 IP and device usage metrics on a daily and weekly basis. This is an demo implementation, focusing on clarity and ease of demonstration.

---

## Table of Contents

1. [Architecture Diagram](#architecture-diagram)
2. [Prerequisites](#prerequisites)
3. [Environment Variables](#environment-variables)
4. [Setup](#setup)
   - [Create ECR Repository](#0-create-ecr-repository)
   - [Build & Push Spark Docker Image](#1-build--push-spark-docker-image)
   - [Provision Infrastructure (Terraform)](#2-provision-infrastructure-terraform)
   - [Configure kubectl](#3-configure-kubectl)
   - [Install Spark Operator](#4-install-spark-operator)
5. [Running the Pipeline](#running-the-pipeline)
   - [Generate Sample Logs](#generate-sample-logs)
   - [Ingest Data into Iceberg](#ingest-data-into-iceberg)
   - [Run Analytics Job](#run-analytics-job)
6. [Accessing Results](#accessing-results)
7. [Project Structure](#project-structure)
8. [Assumptions & Decisions](#assumptions--decisions)
9. [Observability & Performance Metrics](#observability--performance-metrics)
10. [Next Steps](#next-steps)


---

## Architecture Diagram

An architecture diagram illustrating the data flow, components, and interactions is available at `docs/architecture_diagram.png`.

---

## Prerequisites

- **AWS Account** with admin privileges
- **AWS CLI** installed and configured (`aws configure`)
- **Docker** (v20.x+)
- **kubectl** (v1.25+)
- **Helm** (v3.x)
- **Terraform** (v1.0+)
- **Python** (v3.8+)

---

## Environment Variables

Set these before proceeding:

```bash
export REGION=us-east-1
export ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export ECR_URI=${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/iceberg-demo:latest
```

---

## Setup

### 0. Create ECR Repository

```bash
aws ecr create-repository --repository-name iceberg-demo
```

### 1. Build & Push Spark Docker Image

```bash
cd spark

docker build --no-cache -t iceberg-demo .

docker tag iceberg-demo:latest $ECR_URI
docker push $ECR_URI
cd ..
```

### 2. Provision Infrastructure (Terraform)

```bash
cd terraform
terraform init
terraform plan -out=tfplan
terraform apply "tfplan"
cd ..
```

### 3. Configure kubectl

```bash
aws eks update-kubeconfig --name iceberg-demo-eks --region $REGION
kubectl get nodes
```

### 4. Install Spark Operator

```bash
helm repo add spark-operator https://kubeflow.github.io/spark-operator
helm repo update
helm install spark-operator spark-operator/spark-operator \
  --namespace spark-operator --create-namespace --wait
```

---

## Running the Pipeline

### Generate Sample Logs

```bash
python3 scripts/generate_sample_logs.py --count 1000000 --out testfiles/sample.log
```

### Run Pipeline (Ingest & Analytics)

```bash
scripts/load_new_data.sh demo testfiles/sample.log
```

### Watch Job Status

```bash
kubectl get sparkapplications -w
```

---

## Accessing Results

- **S3 Buckets**
  - Raw logs: `s3://iceberg-demo-raw-demo/`
  - Iceberg warehouse: `s3://iceberg-demo-warehouse-demo/`

- **Hive Tables** (via Spark SQL):
  ```bash
  spark-sql \
    --conf spark.sql.catalog.demo.type=hadoop \
    --conf spark.sql.catalog.demo.warehouse=s3a://iceberg-demo-warehouse-demo/ \
    --conf spark.sql.extensions=org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions \
    -e "SHOW TABLES IN demo.analytics;"
  ```

- **Hive Tables** (via Spark SQL - Locally):

  ```bash
  spark-sql \
  --master local[1] \
  --jars spark/jars/iceberg-spark-runtime-3.5_2.12-1.4.3.jar,spark/jars/hadoop-aws-3.3.4.jar,spark/jars/aws-java-sdk-bundle-1.11.901.jar \
  --conf spark.sql.extensions=org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions \
  --conf spark.sql.catalog.demo=org.apache.iceberg.spark.SparkCatalog \
  --conf spark.sql.catalog.demo.type=hadoop \
  --conf spark.sql.catalog.demo.warehouse=s3a://iceberg-demo-warehouse-demo/ \
  --conf spark.hadoop.fs.s3a.aws.credentials.provider=com.amazonaws.auth.profile.ProfileCredentialsProvider
  ```


---

## Project Structure

```
├── README.md
├── docs/
│   ├── architecture_diagram.png
├── scripts/
│   ├── generate_sample_logs.py
│   └── load_new_data.sh
├── spark/
│   ├── Dockerfile
│   ├── jobs/
│   │   ├── ingest.py
│   │   ├── run_sql.py
│   │   └── analytics.sql
│   └── k8s/
│       ├── sparkapp-ingest.yaml.tpl
│       ├── sparkapp-analytics.yaml.tpl
│       ├── serviceaccount.yaml.tpl
│       └── spark-sa-rbac.yaml
├── terraform/
│   ├── main.tf
│   ├── modules/
│   │   ├── eks/
│   │   ├── network/
│   │   ├── iam_irsa/
│   │   └── s3/
│   ├── terraform.tfvars
│   └── variables.tf
└── testfiles/
    └── sample.log
```

---

## Assumptions & Decisions

- **Data Scale:** Demo-scale (~1 million records for demo) for quick iteration.
- **Catalog:** Hadoop catalog on S3 for simplicity.
- **Security:** IAM Roles for Service Accounts (IRSA) for S3 access.

---

## Observability & Performance Metrics

- **Spark Metrics:** via Spark Spark UI.
- *(Placeholder)* Future integration: Prometheus/Grafana dashboards.

---

## Next Steps

1. Add Hive Metastore backend (RDS).
2. Code cleanup, externalize few hard code varaibles like s3 path as arguments

---

