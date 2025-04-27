# GitHub OIDC Provider
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

# GitHub Actions用のIAMロール
resource "aws_iam_role" "gha_cp" {
  name = "github-actions-codepipeline"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Condition = {
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_repository_id}:*"
          }
        }
      }
    ]
  })
}

# GitHub Actions用のIAMポリシー
resource "aws_iam_policy" "gha_cp" {
  name = "github-actions-codepipeline-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "codepipeline:StartPipelineExecution"
        ]
        Effect   = "Allow"
        Resource = aws_codepipeline.pipeline.arn
      }
    ]
  })
}

# ポリシーのアタッチ
resource "aws_iam_role_policy_attachment" "gha_cp_attach" {
  role       = aws_iam_role.gha_cp.name
  policy_arn = aws_iam_policy.gha_cp.arn
} 