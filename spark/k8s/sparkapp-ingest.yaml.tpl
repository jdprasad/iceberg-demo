apiVersion: sparkoperator.k8s.io/v1beta2
kind: SparkApplication
metadata:
  name: ingest-job
  namespace: default
spec:
  type: Python
  mode: cluster
  image: "${ECR_URI}"                                                            # ←-- edit this once you push the image
  
  sparkConf:
    # use the S3A scheme for file staging
    "spark.kubernetes.file.upload.path": "s3a://iceberg-demo-raw-demo/_file-upload"
    
    # explicit FileSystem impl (already baked into the image via Dockerfile)
    "spark.hadoop.fs.s3a.impl": "org.apache.hadoop.fs.s3a.S3AFileSystem"

    # IRSA-compatible credentials provider
    "spark.hadoop.fs.s3a.aws.credentials.provider": "com.amazonaws.auth.WebIdentityTokenCredentialsProvider"

    # ensure spark-submit can find S3AFileSystem at runtime
    "spark.driver.extraClassPath":   "/opt/bitnami/spark/jars/hadoop-aws-3.3.4.jar:/opt/bitnami/spark/jars/aws-java-sdk-bundle-1.11.901.jar"
    "spark.executor.extraClassPath": "/opt/bitnami/spark/jars/hadoop-aws-3.3.4.jar:/opt/bitnami/spark/jars/aws-java-sdk-bundle-1.11.901.jar"

    # --- Spark to use - Iceberg Hadoop Catalog ---
    "spark.sql.extensions": "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions"
    "spark.sql.catalog.demo": "org.apache.iceberg.spark.SparkCatalog"
    "spark.sql.catalog.demo.type": "hadoop"
    "spark.sql.catalog.demo.warehouse": "s3a://iceberg-demo-warehouse-demo/"
    
    # tell Iceberg to write a version-hint.text file after each commit
    "spark.sql.catalog.demo.write.version-hint.enabled": "true"

  imagePullPolicy: Always
  mainApplicationFile: "local:///opt/jobs/ingest.py"
  sparkVersion: "3.5.1"
  restartPolicy:
    type: Never
  timeToLiveSeconds: 300                # keep pods for 5 min after they exit
  volumes:
    - name: spark-config
      configMap:
        name: spark-defaults
  driver:
    cores: 1
    memory: 2g
    serviceAccount: spark-sa
    env:
      - name: HADOOP_USER_NAME
        value: spark          

      
  executor:
    cores: 1
    instances: 3
    memory: 2g
    serviceAccount: spark-sa
    env:
      - name: HADOOP_USER_NAME
        value: spark          

  arguments:
    - "--input"   
    - "s3a://iceberg-demo-raw-demo/"
    - "--warehouse"
    - "s3a://iceberg-demo-warehouse-demo/"
    - "--table"
    - "logs"