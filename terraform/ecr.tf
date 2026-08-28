# =========================================================
# ECR Repository
# =========================================================

resource "aws_ecr_repository" "app" {
  name = "devops-bootcamp-app"

  # Production-style:
  # Prevent an existing image tag from being overwritten.
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  # Temporary for now.
  # Allows Terraform to delete the repository even when
  # images still exist inside it.
  #
  # For production, consider removing this.
  force_delete = true

  tags = {
    Name        = "devops-bootcamp-app"
    Environment = "dev"
    Project     = "devops-bootcamp"
  }
}


# =========================================================
# ECR Lifecycle Policy
# =========================================================
#
# FUTURE:
# Enable this when we want AWS to automatically clean up
# old Docker images and control ECR storage costs.
#
# Example:
#
# resource "aws_ecr_lifecycle_policy" "app" {
#   repository = aws_ecr_repository.app.name
#
#   policy = jsonencode({
#     rules = [
#       {
#         rulePriority = 1
#         description  = "Keep only the latest 10 tagged images"
#
#         selection = {
#           tagStatus      = "tagged"
#           tagPatternList = ["*"]
#           countType      = "imageCountMoreThan"
#           countNumber    = 10
#         }
#
#         action = {
#           type = "expire"
#         }
#       },
#       {
#         rulePriority = 2
#         description  = "Remove untagged images after 1 day"
#
#         selection = {
#           tagStatus   = "untagged"
#           countType   = "sinceImagePushed"
#           countUnit   = "days"
#           countNumber = 1
#         }
#
#         action = {
#           type = "expire"
#         }
#       }
#     ]
#   })
# }