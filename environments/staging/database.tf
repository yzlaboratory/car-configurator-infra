# --- 1. RDS (PostgreSQL) ---

# Subnetz-Gruppe für RDS (muss in privaten Subnetzen sein)
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-rds-subnet-group"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  tags = {
    Name = "${var.project_name}-rds-subnet-group"
  }
}

# Die RDS-Instanz selbst
resource "aws_db_instance" "orders" {
  allocated_storage           = 20
  storage_type                = "gp2"
  engine                      = "postgres"
  engine_version              = "17.6"
  instance_class              = "db.t3.micro"
  db_name                     = "ordersdb" # PostgreSQL-Namen dürfen keine Bindestriche haben
  # Liest den Benutzernamen und das Passwort aus dem Secrets Manager
  username             = jsondecode(aws_secretsmanager_secret_version.db_credentials.secret_string)["username"]
  password             = jsondecode(aws_secretsmanager_secret_version.db_credentials.secret_string)["password"]
  db_subnet_group_name        = aws_db_subnet_group.main.name
  vpc_security_group_ids      = [aws_security_group.rds.id]
  publicly_accessible         = false
  skip_final_snapshot         = true # WICHTIG: Nur für Demos, nicht für Produktion
}

# --- 2. DynamoDB (2x Tables) ---
resource "aws_dynamodb_table" "catalog_table" {
  name         = "${var.project_name}-catalog"
  billing_mode = "PAY_PER_REQUEST" # Serverless-Modus
  hash_key     = "modelId"

  attribute {
    name = "modelId"
    type = "S" # S = String
  }

  tags = {
    Name        = "${var.project_name}-catalog"
    Environment = "staging"
  }
}

resource "aws_dynamodb_table" "configs_table" {
  name         = "${var.project_name}-configs"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "configId"

  attribute {
    name = "configId"
    type = "S"
  }

  tags = {
    Name        = "${var.project_name}-configs"
    Environment = "staging"
  }
}