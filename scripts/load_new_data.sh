#!/usr/bin/env bash
# -------------------------------------------------------------------------
# Push a new log file to S3, (re)render & apply all Spark manifests,
# re-run ingest + analytics jobs, and wait until they finish.
#
# Usage: ./load_new_data.sh  [env]  [path/to/logfile]
# Example: ./load_new_data.sh demo ./sample_new.log
# -------------------------------------------------------------------------
set -euo pipefail

# ──────────────────────────────────────────────────────────────────────────
# Helper to print a separator line
# ──────────────────────────────────────────────────────────────────────────
sep() {
  echo
  # prints a 60-character line of dashes
  printf '%*s\n' 80 '' | tr ' ' '#'
  echo
}

# ──────────────────────────────────────────────────────────────────────────
# 0) REGION & AWS_ACCOUNT setup
# ──────────────────────────────────────────────────────────────────────────
# Default region (override with export REGION=your-region if you like)
: "${REGION:=us-east-1}"

# Grab AWS account via CLI
ACCOUNT_ID=$(aws sts get-caller-identity \
  --query Account --output text)

# ──────────────────────────────────────────────────────────────────────────
# 1) Parse args & compute bucket names
# ──────────────────────────────────────────────────────────────────────────
ENV=${1:-demo}
LOG=${2:-./extra.log}
RAW_BUCKET="s3://iceberg-demo-raw-${ENV}"
WAREHOUSE_URI="s3a://iceberg-demo-warehouse-${ENV}/"

sep
echo "📤 Uploading $(basename "$LOG") to $RAW_BUCKET"
aws s3 cp "$LOG" "$RAW_BUCKET/$(basename "$LOG")"
echo "Upload completed"
sep

# ──────────────────────────────────────────────────────────────────────────
# 2) Fetch IRSA Role ARN & build ECR URI
# ──────────────────────────────────────────────────────────────────────────
export SPARK_SA_ROLE_ARN=$(terraform -chdir=terraform output -raw spark_sa_role_arn)
export ECR_URI="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/iceberg-demo:latest"

# ─────────────────────────────────────────────────────────
# 3) Render & apply Kubernetes manifests
# ─────────────────────────────────────────────────────────

# 3a) ServiceAccount + RBAC
echo "🛠  Rendering & applying ServiceAccount..."
envsubst < spark/k8s/serviceaccount.yaml.tpl | kubectl apply -f -
echo "🛠  Applying RBAC binding..."
kubectl apply -f spark/k8s/spark-sa-rbac.yaml

# 3b) SparkApplications
for tpl in \
  spark/k8s/sparkapp-ingest.yaml.tpl \
  spark/k8s/sparkapp-analytics.yaml.tpl
do
  echo "🛠  Rendering & applying $(basename "$tpl")..."
  envsubst < "$tpl" | kubectl apply -f -
done
echo "✅ All SparkApplication manifests are applied"
sep

# ──────────────────────────────────────────────────────────────────────────
# 4) Launch & wait for ingest + analytics SparkApplications
# ──────────────────────────────────────────────────────────────────────────
for app in ingest analytics; do
  echo -e "\n🚀 Launching ${app}-job"
  kubectl delete sparkapplication "${app}-job" --ignore-not-found --now || true

  # Re-render the template and apply directly from stdin
  envsubst < "spark/k8s/sparkapp-${app}.yaml.tpl" \
    | kubectl apply -f -

  echo "⏳ Waiting for ${app}-job to finish (COMPLETED|FAILED)…"
  kubectl wait sparkapplication/"${app}-job" \
    --for=jsonpath='{.status.applicationState.state}'=COMPLETED \
    --timeout=600s || true

  state=$(kubectl get sparkapplication "${app}-job" \
              -o jsonpath='{.status.applicationState.state}')
  if [[ "$state" == "FAILED" ]]; then
    echo "❌ ${app}-job ended in FAILED state"
    exit 1
  fi
  echo "✅ ${app}-job finished with state $state"
  sep
done