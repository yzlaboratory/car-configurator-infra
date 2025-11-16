variable "aws_region" {
  description = "The AWS region to deploy the infrastructure to."
  type        = string
  default     = "eu-central-1"
}

variable "project_name" {
  description = "A name prefix for all created resources."
  type        = string
  default     = "car-configurator-staging"
}

variable "container_image_orders" {
  description = "The Docker container image to deploy (e.g., from ECR)."
  type        = string
  # Sie würden hier Ihr ECR-Image eintragen:
  # default = "<ihre-aws-account-id>.dkr.ecr.eu-central-1.amazonaws.com/mein-microservice:latest"
  default = "772161516556.dkr.ecr.eu-central-1.amazonaws.com/car-configurator/api-orders:staging" # Ihr aktueller Platzhalter
}

variable "container_image_configs" {
  description = "The Docker container image to deploy (e.g., from ECR)."
  type        = string
  # Sie würden hier Ihr ECR-Image eintragen:
  # default = "<ihre-aws-account-id>.dkr.ecr.eu-central-1.amazonaws.com/mein-microservice:latest"
  default = "772161516556.dkr.ecr.eu-central-1.amazonaws.com/car-configurator/api-configs:staging" # Ihr aktueller Platzhalter
}

variable "container_image_catalog" {
  description = "The Docker container image to deploy (e.g., from ECR)."
  type        = string
  # Sie würden hier Ihr ECR-Image eintragen:
  default = "772161516556.dkr.ecr.eu-central-1.amazonaws.com/car-configurator/api-catalog:staging"
}

variable "container_port" {
  default = 8080
}