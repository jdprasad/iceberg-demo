resource "aws_iam_role" "spark" {
  name = "${var.env}-spark-sa"
  assume_role_policy = data.aws_iam_policy_document.sa.json
}

data "aws_iam_policy_document" "sa" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }
  }
}

resource "aws_iam_role_policy" "s3_access" {
  role = aws_iam_role.spark.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      # bucket-level actions
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket", "s3:GetBucketLocation"]
        Resource = var.s3_buckets            
      },
      # object-level actions
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:AbortMultipartUpload",
          "s3:ListMultipartUploadParts",
          "s3:CreateMultipartUpload"
        ]
        Resource = [for b in var.s3_buckets : "${b}/*"]
      }
    ]
  })
}


output "spark_role_arn" {
  description = "ARN of the IAM role for Spark ServiceAccount"
  value       = aws_iam_role.spark.arn
}
