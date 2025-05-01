apiVersion: v1
kind: ServiceAccount
metadata:
  name: spark-sa
  namespace: default
  annotations:
    eks.amazonaws.com/role-arn: "${SPARK_SA_ROLE_ARN}"
