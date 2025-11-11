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
  manage_master_user_password = true
  username                    = "lumra"
  db_subnet_group_name        = aws_db_subnet_group.main.name
  vpc_security_group_ids      = [aws_security_group.rds.id]
  publicly_accessible         = false
  skip_final_snapshot         = true # WICHTIG: Nur für Demos, nicht für Produktion
}


# --- 2. DynamoDB (2x Tables) ---

# Tabelle 1 (z.B. für den "Catalog-Service")
resource "aws_dynamodb_table" "catalog_table" {
  name         = "${var.project_name}-catalog"
  billing_mode = "PAY_PER_REQUEST" # Serverless-Modus
  hash_key     = "partId"

  attribute {
    name = "partId"
    type = "S" # S = String
  }

  tags = {
    Name        = "${var.project_name}-catalog"
    Environment = "staging"
  }
}

# Tabelle 2 (z.B. für den "Order-Service")
resource "aws_dynamodb_table" "config_table" {
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