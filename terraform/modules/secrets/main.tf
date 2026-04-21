variable "env" { type = string }
variable "oidc_provider_arn" { type = string }
variable "oidc_provider_url" { type = string }
variable "namespace" {
  type    = string
  default = "app"
}

locals { db_names = ["mongodb", "mysql", "redis"] }

resource "aws_secretsmanager_secret" "db" {
  for_each                = toset(local.db_names)
  name                    = "ilmiya/${var.env}/${each.key}"
  recovery_window_in_days = 7
  tags                    = { Environment = var.env }
}

resource "aws_secretsmanager_secret_rotation" "db" {
  for_each            = toset(local.db_names)
  secret_id           = aws_secretsmanager_secret.db[each.key].id
  rotation_lambda_arn = aws_lambda_function.secret_rotator.arn
  rotation_rules { automatically_after_days = 30 }
}

data "archive_file" "rotator" {
  type        = "zip"
  output_path = "${path.module}/rotator.zip"
  source {
    content  = "def handler(event, context): pass  # implement per-DB rotation"
    filename = "lambda_function.py"
  }
}

resource "aws_iam_role" "rotator" {
  name = "ilmiya-${var.env}-secret-rotator"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "rotator" {
  role = aws_iam_role.rotator.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["secretsmanager:GetSecretValue", "secretsmanager:PutSecretValue", "secretsmanager:UpdateSecretVersionStage"]
      Resource = "arn:aws:secretsmanager:*:*:secret:ilmiya/${var.env}/*"
    }]
  })
}

resource "aws_lambda_function" "secret_rotator" {
  function_name    = "ilmiya-${var.env}-secret-rotator"
  role             = aws_iam_role.rotator.arn
  handler          = "lambda_function.handler"
  runtime          = "python3.12"
  filename         = data.archive_file.rotator.output_path
  source_code_hash = data.archive_file.rotator.output_base64sha256
}

resource "aws_lambda_permission" "secretsmanager" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.secret_rotator.function_name
  principal     = "secretsmanager.amazonaws.com"
}

# --- IRSA Role for External Secrets Operator ---
resource "aws_iam_role" "external_secrets" {
  name = "ilmiya-${var.env}-external-secrets"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Federated = var.oidc_provider_arn }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${var.oidc_provider_url}:sub" = "system:serviceaccount:external-secrets:external-secrets-sa"
          "${var.oidc_provider_url}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "external_secrets" {
  role = aws_iam_role.external_secrets.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
      Resource = "arn:aws:secretsmanager:*:*:secret:ilmiya/${var.env}/*"
    }]
  })
}

output "external_secrets_role_arn" { value = aws_iam_role.external_secrets.arn }
output "secret_arns" { value = { for k, v in aws_secretsmanager_secret.db : k => v.arn } }
