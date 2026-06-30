# DB credentials live in Secrets Manager — never in task defs, env files, or git.
# A random password is generated and injected into Postgres and the backend at
# runtime via the task definition `secrets` block (valueFrom).

resource "random_password" "db" {
  length  = 24
  special = false
}

resource "aws_secretsmanager_secret" "db_password" {
  name_prefix = "${var.project}/db-password-"
  description = "ShopNow Postgres password"
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = random_password.db.result
}
