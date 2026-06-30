# Permissions for the CI deploy role. Scoped to project resources where AWS
# supports it (state bucket, ECR repos, secrets, IAM roles by name prefix);
# wildcards only for describe/list and services without resource-level control.
#
# NOTE: this is a pragmatic first cut. On the first CI deploy, tighten or extend
# based on any AccessDenied seen in the run logs.
data "aws_iam_policy_document" "ci" {
  # --- Terraform remote state ---
  statement {
    sid       = "StateBucketList"
    actions   = ["s3:ListBucket", "s3:GetBucketVersioning"]
    resources = ["arn:aws:s3:::${var.state_bucket}"]
  }
  statement {
    sid       = "StateObjectRW"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["arn:aws:s3:::${var.state_bucket}/*"]
  }

  # --- ECR: auth is account-wide; push/pull scoped to the project repos ---
  statement {
    sid       = "EcrAuth"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }
  statement {
    sid = "EcrRepoRW"
    actions = [
      "ecr:BatchCheckLayerAvailability", "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage", "ecr:PutImage", "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart", "ecr:CompleteLayerUpload",
      "ecr:DescribeRepositories", "ecr:ListImages",
    ]
    resources = ["arn:aws:ecr:${var.region}:${data.aws_caller_identity.current.account_id}:repository/${var.project}/*"]
  }

  # --- Orchestrator + supporting services provisioned by Terraform ---
  # These services have limited resource-level IAM support; describe/list are
  # read-only and the create/update actions are confined to this account.
  statement {
    sid = "InfraServices"
    actions = [
      "ecs:*", "eks:*", "elasticloadbalancing:*", "servicediscovery:*",
      "application-autoscaling:*", "logs:*", "ec2:Describe*",
      "ec2:CreateTags", "ec2:*VpcEndpoint*", "cloudwatch:*",
    ]
    resources = ["*"]
  }

  # --- Secrets Manager: only the project's secrets ---
  statement {
    sid = "ProjectSecrets"
    actions = [
      "secretsmanager:CreateSecret", "secretsmanager:DeleteSecret",
      "secretsmanager:GetSecretValue", "secretsmanager:PutSecretValue",
      "secretsmanager:DescribeSecret", "secretsmanager:TagResource",
      "secretsmanager:GetResourcePolicy",
    ]
    resources = ["arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:secret:${var.project}/*"]
  }

  # --- IAM: role lifecycle + PassRole confined to project-named roles ---
  statement {
    sid = "ProjectIamRoles"
    actions = [
      "iam:CreateRole", "iam:DeleteRole", "iam:GetRole", "iam:TagRole",
      "iam:AttachRolePolicy", "iam:DetachRolePolicy",
      "iam:PutRolePolicy", "iam:DeleteRolePolicy", "iam:GetRolePolicy",
      "iam:ListRolePolicies", "iam:ListAttachedRolePolicies",
      "iam:CreatePolicy", "iam:DeletePolicy", "iam:GetPolicy", "iam:GetPolicyVersion",
      "iam:PassRole", "iam:ListInstanceProfilesForRole",
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project}-*",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/${var.project}-*",
    ]
  }

  # --- IAM: read OIDC provider (EKS IRSA) ---
  statement {
    sid       = "IamOidcRead"
    actions   = ["iam:GetOpenIDConnectProvider", "iam:ListOpenIDConnectProviders"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ci" {
  name   = "${var.project}-github-actions-ci"
  policy = data.aws_iam_policy_document.ci.json
}

resource "aws_iam_role_policy_attachment" "ci" {
  role       = aws_iam_role.ci.name
  policy_arn = aws_iam_policy.ci.arn
}
