# IAM-Rolle für Fargate-Tasks, um Container-Images zu pullen und Logs zu schreiben
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.project_name}-ecs-task-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# IAM-Rolle für die Anwendung *innerhalb* des Containers
# Erlaubt dem Container, mit anderen AWS-Diensten (z.B. DynamoDB) zu sprechen
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project_name}-ecs-task-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# Erlaubt dem Container, auf DynamoDB zuzugreifen (für dieses Beispiel)
resource "aws_iam_role_policy_attachment" "ecs_task_dynamodb_policy" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
  # In einer echten Produktion würden Sie dies auf die ARNs der Tabellen beschränken
}

# Erlaubt dem Container, auf Postgres zuzugreifen (für dieses Beispiel)
resource "aws_iam_role_policy_attachment" "ecs_task_postgres_policy" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonRDSFullAccess"
  # In einer echten Produktion würden Sie dies auf die ARNs der Tabellen beschränken
}

resource "aws_iam_role_policy" "task_permissions1" {
  name = "car-configurator_task_permissions"
  role = aws_iam_role.ecs_task_role.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "iam:PassRole",
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "task_permissions2" {
  name = "car-configurator_task_permissions"
  role = aws_iam_role.ecs_task_execution_role.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "iam:PassRole",
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}