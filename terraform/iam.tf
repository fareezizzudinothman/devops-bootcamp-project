# node3 iam role

data "aws_iam_policy_document" "ssm_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ssm" {
  name               = "devops-ssm-role"
  assume_role_policy = data.aws_iam_policy_document.ssm_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm" {
  name = "devops-ssm-profile"
  role = aws_iam_role.ssm.name
}

# =========================================================
# Ansible Controller Role
# Used by Node2
# =========================================================

data "aws_iam_policy_document" "ansible_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ansible" {
  name               = "devops-ansible-role"
  assume_role_policy = data.aws_iam_policy_document.ansible_assume_role.json
}


# =========================================================
# Node2 must also be an SSM Managed Instance
# =========================================================

resource "aws_iam_role_policy_attachment" "ansible_ssm_core" {
  role       = aws_iam_role.ansible.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


# =========================================================
# Permissions for Ansible Controller
# =========================================================

resource "aws_iam_role_policy" "ansible_controller" {
  name = "devops-ansible-controller-policy"
  role = aws_iam_role.ansible.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [

      # -----------------------------------------------
      # AWS Systems Manager
      # -----------------------------------------------
      {
        Sid    = "SSMAccess"
        Effect = "Allow"

        Action = [
          "ssm:StartSession",
          "ssm:TerminateSession",
          "ssm:ResumeSession",
          "ssm:DescribeInstanceInformation"
        ]

        Resource = "*"
      },

      # -----------------------------------------------
      # S3 bucket used by Ansible AWS SSM plugin
      # -----------------------------------------------
      {
        Sid    = "S3BucketAccess"
        Effect = "Allow"

        Action = [
          "s3:GetBucketLocation",
          "s3:ListBucket"
        ]

        Resource = "arn:aws:s3:::devops-bootcamp-ansible-fareezizzudinothman"
      },

      {
        Sid    = "S3ObjectAccess"
        Effect = "Allow"

        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]

        Resource = "arn:aws:s3:::devops-bootcamp-ansible-fareezizzudinothman/*"
      }
    ]
  })
}


# =========================================================
# Instance Profile for Node2
# =========================================================

resource "aws_iam_instance_profile" "ansible" {
  name = "devops-ansible-profile"
  role = aws_iam_role.ansible.name
}




# Node1 - Webserver Role
# =========================================================

data "aws_iam_policy_document" "webserver_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "webserver" {
  name               = "devops-webserver-role"
  assume_role_policy = data.aws_iam_policy_document.webserver_assume_role.json
}

resource "aws_iam_role_policy_attachment" "webserver_ssm" {
  role       = aws_iam_role.webserver.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "webserver_ecr" {
  role       = aws_iam_role.webserver.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_instance_profile" "webserver" {
  name = "devops-webserver-profile"
  role = aws_iam_role.webserver.name
}




# Node3 - Monitoring Role
# =========================================================

data "aws_iam_policy_document" "monitoring_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "monitoring" {
  name               = "devops-monitoring-role"
  assume_role_policy = data.aws_iam_policy_document.monitoring_assume_role.json
}

resource "aws_iam_role_policy_attachment" "monitoring_ssm" {
  role       = aws_iam_role.monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "monitoring" {
  name = "devops-monitoring-profile"
  role = aws_iam_role.monitoring.name
}


# ===================================================================================
# GitHub Actions Role

# =========================================================
# GitHub Actions OIDC Provider
# =========================================================

data "tls_certificate" "github_actions" {
  url = "https://token.actions.githubusercontent.com"
}

resource "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    data.tls_certificate.github_actions.certificates[0].sha1_fingerprint
  ]
}


# =========================================================
# GitHub Actions IAM Role (Create role)
# =========================================================

data "aws_iam_policy_document" "github_actions_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type = "Federated"

      identifiers = [
        aws_iam_openid_connect_provider.github_actions.arn
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"

      values = [
        "sts.amazonaws.com"
      ]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"

      values = [
        "repo:fareezizzudinothman/devops-bootcamp-project:*"
      ]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name = "devops-github-actions-role"

  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role.json
}


# =========================================================
# GitHub Actions - ECR Push Permission
# ECR permissions
# =========================================================

resource "aws_iam_role_policy" "github_actions_ecr" {
  name = "devops-github-actions-ecr"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "ECRAuthorization"
        Effect = "Allow"

        Action = [
          "ecr:GetAuthorizationToken"
        ]

        Resource = "*"
      },

      {
        Sid    = "ECRPush"
        Effect = "Allow"

        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart"
        ]

        Resource = aws_ecr_repository.app.arn
      }
    ]
  })
}

# =========================================================
# GitHub Actions - SSM Permission
# Allows GitHub Actions to trigger deployment on Node2
# =========================================================

resource "aws_iam_role_policy" "github_actions_ssm" {
  name = "devops-github-actions-ssm"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "SSMDeployment"
        Effect = "Allow"

        Action = [
          "ssm:SendCommand"
        ]

        Resource = "*"
      }
    ]
  })
}