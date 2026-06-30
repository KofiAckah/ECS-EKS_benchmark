data "aws_caller_identity" "current" {}

# GitHub's OIDC issuer cert thumbprint (fetched dynamically so it survives rotation).
data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github.certificates[0].sha1_fingerprint]
}

# Trust policy: ONLY GitHub Actions runs from this repo's `main` branch, with the
# sts.amazonaws.com audience, may assume the role. Tight `sub` = small blast radius.
data "aws_iam_policy_document" "trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_owner}/${var.github_repo}:ref:refs/heads/${var.allowed_branch}"]
    }
  }
}

resource "aws_iam_role" "ci" {
  name                 = "${var.project}-github-actions-ci"
  assume_role_policy   = data.aws_iam_policy_document.trust.json
  max_session_duration = 3600
}

output "role_arn" {
  description = "Set this as the AWS_ROLE_ARN GitHub secret."
  value       = aws_iam_role.ci.arn
}
