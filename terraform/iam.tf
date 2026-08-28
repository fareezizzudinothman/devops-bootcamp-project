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