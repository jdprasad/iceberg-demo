# ------------------------------------------------------------------
# Base OSS Spark runtime
# ------------------------------------------------------------------
FROM bitnami/spark:3.5.1

# ------------------------------------------------------------------
# Layer 0 – become root
# ------------------------------------------------------------------
USER root

# ------------------------------------------------------------------
# Layer 1 – add curl (needed to pull JARs)
# ------------------------------------------------------------------
RUN apt-get update \
 && apt-get install -y --no-install-recommends curl \
 && rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------------
# ★ NEW Layer 1.5 – create a real user "spark" with UID 1001 ★
# ------------------------------------------------------------------
#  * Adds an /etc/passwd entry so Hadoop’s UnixLoginModule succeeds.
#  * Gives the user a writable home dir and ownership of Spark + jobs.

COPY jobs/ /opt/jobs/

 RUN useradd -m -u 1001 spark && \
    mkdir -p /opt/bitnami/spark/work && \
    chown -R spark:spark /opt/jobs /opt/bitnami/spark/work /home/spark


# ------------------------------------------------------------------
# Layer 2 – drop the Iceberg runtime JAR into Spark’s classpath
# ------------------------------------------------------------------
ENV ICEBERG_VER=1.4.3
RUN curl -L -o /opt/bitnami/spark/jars/iceberg-spark-runtime.jar \
    "https://repo.maven.apache.org/maven2/org/apache/iceberg/iceberg-spark-runtime-3.5_2.12/${ICEBERG_VER}/iceberg-spark-runtime-3.5_2.12-${ICEBERG_VER}.jar"


# ──────────────────────────────────────────────────────────────────
# ★ NEW Layer 2.1 – add Iceberg Hive catalog support
# ──────────────────────────────────────────────────────────────────
RUN curl -L -o /opt/bitnami/spark/jars/iceberg-hive-runtime-3.5_2.12-${ICEBERG_VER}.jar \
    "https://repo.maven.apache.org/maven2/org/apache/iceberg/iceberg-hive-runtime-3.5_2.12/${ICEBERG_VER}/iceberg-hive-runtime-3.5_2.12-${ICEBERG_VER}.jar"


# ──────────────────────────────────────────────────────────────────
# ★ NEW Layer – add both MySQL & PostgreSQL JDBC drivers ★
# ──────────────────────────────────────────────────────────────────
ENV MYSQL_CONN_VER=8.3.0 \
    POSTGRES_JDBC_VER=42.6.0

RUN curl -L -o /opt/bitnami/spark/jars/mysql-connector-java-${MYSQL_CONN_VER}.jar \
    "https://repo.maven.apache.org/maven2/mysql/mysql-connector-java/${MYSQL_CONN_VER}/mysql-connector-java-${MYSQL_CONN_VER}.jar" \
 && curl -L -o /opt/bitnami/spark/jars/postgresql-${POSTGRES_JDBC_VER}.jar \
    "https://repo1.maven.org/maven2/org/postgresql/postgresql/${POSTGRES_JDBC_VER}/postgresql-${POSTGRES_JDBC_VER}.jar"



# ------------------------------------------------------------------
# Layer 2.5 – add AWS S3A support (Hadoop-AWS + AWS SDK)
# ------------------------------------------------------------------
ENV HADOOP_AWS_VER=3.3.4 \
    AWS_SDK_VER=1.11.901
RUN curl -L -o /opt/bitnami/spark/jars/hadoop-aws-${HADOOP_AWS_VER}.jar \
    "https://repo.maven.apache.org/maven2/org/apache/hadoop/hadoop-aws/${HADOOP_AWS_VER}/hadoop-aws-${HADOOP_AWS_VER}.jar" && \
    curl -L -o /opt/bitnami/spark/jars/aws-java-sdk-bundle-${AWS_SDK_VER}.jar \
    "https://repo.maven.apache.org/maven2/com/amazonaws/aws-java-sdk-bundle/${AWS_SDK_VER}/aws-java-sdk-bundle-${AWS_SDK_VER}.jar"

# ------------------------------------------------------------------
# Layer 3 – add our job files
# ------------------------------------------------------------------
COPY jobs/ /opt/jobs/
RUN chmod +x /opt/jobs/*.py \
 && chown -R spark:spark /opt/jobs

WORKDIR /opt/jobs

# ------------------------------------------------------------------
# ★ Switch permanently to the named, non-root user ★
# ------------------------------------------------------------------
USER 1001

ENTRYPOINT ["/opt/bitnami/scripts/spark/entrypoint.sh"]
