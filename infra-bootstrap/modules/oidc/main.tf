# --- GitHub OIDC Provider for Secure Deployment ---
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}



resource "aws_iam_role" "github_actions_deploy_role" {
  name = "${var.project_name}-github-deploy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.github.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          "token.actions.githubusercontent.com:sub" = [
            "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/main"
          ]
        }
      }
    }]
  })
}

resource "aws_iam_policy" "github_deploy_policy" {
  name        = "${var.project_name}-github-deploy-policy"
  description = "Consolidated policy to manage full infrastructure lifecycle following least privilege"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # 1. S3 Management (Website bucket + backend ops)
      {
        Effect = "Allow"
        Action = ["s3:*"]
        Resource = [
          "arn:aws:s3:::${var.project_name}-*",
          "arn:aws:s3:::${var.project_name}-*/*",
          "arn:aws:s3:::admin-terraform-state-*",
          "arn:aws:s3:::admin-terraform-state-*/*"
        ]
      },
      # 2. DynamoDB Management
      {
        Effect   = "Allow"
        Action   = ["dynamodb:*"]
        Resource = ["arn:aws:dynamodb:*:*:table/${var.project_name}-*"]
      },
      # 3. Lambda Management
      {
        Effect   = "Allow"
        Action   = ["lambda:*"]
        Resource = ["arn:aws:lambda:*:*:function:${var.project_name}-*"]
      },
      # 4. CloudFront Management
      {
        Effect = "Allow"
        Action = [
          "cloudfront:CreateInvalidation",
          "cloudfront:GetDistribution",
          "cloudfront:GetDistributionConfig",
          "cloudfront:UpdateDistribution",
          "cloudfront:CreateDistribution",
          "cloudfront:DeleteDistribution",
          "cloudfront:GetInvalidation",
          "cloudfront:ListDistributions",
          "cloudfront:ListTagsForResource",
          "cloudfront:TagResource",
          "cloudfront:CreateOriginAccessControl",
          "cloudfront:GetOriginAccessControl",
          "cloudfront:DeleteOriginAccessControl",
          "cloudfront:ListOriginAccessControls"
        ]
        Resource = ["*"]
      },
      # 5. API Gateway Management
      {
        Effect = "Allow"
        Action = [
          "apigateway:GET",
          "apigateway:POST",
          "apigateway:PUT",
          "apigateway:PATCH",
          "apigateway:DELETE",
          "apigateway:TagResource"
        ]
        Resource = ["*"]
      },
      # 6. IAM Scoped Management (For Lambda execution roles)
      {
        Effect = "Allow"
        Action = ["iam:*"]
        Resource = [
          "arn:aws:iam::*:role/${var.project_name}-*",
          "arn:aws:iam::*:policy/${var.project_name}-*",
          "arn:aws:iam::*:oidc-provider/*"
        ]
      },
      # 7. ACM Certificate Management (For Custom domain certificate)
      {
        Effect = "Allow"
        Action = [
          "acm:RequestCertificate",
          "acm:DescribeCertificate",
          "acm:ListCertificates",
          "acm:DeleteCertificate",
          "acm:AddTagsToCertificate",
          "acm:GetCertificate",
          "acm:ListTagsForCertificate"
        ]
        Resource = ["*"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "github_deploy_attach" {
  role       = aws_iam_role.github_actions_deploy_role.name
  policy_arn = aws_iam_policy.github_deploy_policy.arn
}
