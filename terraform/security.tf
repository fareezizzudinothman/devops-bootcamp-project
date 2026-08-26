module "public_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 6.0"

  name            = "devops-public-sg"
  description     = "SG for public web server"
  use_name_prefix = false

  vpc_id = module.my_vpc.vpc_id

  ingress_rules = {
    http = {
      name        = "http"
      cidr_ipv4   = "0.0.0.0/0"
      ip_protocol = "tcp"
      from_port   = 80
      to_port     = 80
      description = "HTTP from internet"
    }

    node-exporter = {
      name        = "node-exporter"
      cidr_ipv4   = "10.0.0.136/32"
      ip_protocol = "tcp"
      from_port   = 9100
      to_port     = 9100
      description = "Prometheus scraping Node Exporter"
    }
  }

  egress_rules = {
    all = {
      cidr_ipv4   = "0.0.0.0/0"
      ip_protocol = "-1"
    }
  }

  tags = {
    Name = "devops-public-sg"
  }
}

module "private_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 6.0"

  name            = "devops-private-sg"
  description     = "SG for private servers"
  use_name_prefix = false

  vpc_id = module.my_vpc.vpc_id

  ingress_rules = {

    node-exporter = {
      name = "node-exporter"
      #     cidr_ipv4   = "10.0.0.0/25"
      cidr_ipv4   = "10.0.0.136/32"
      ip_protocol = "tcp"
      from_port   = 9100
      to_port     = 9100
      description = "Node Exporter from public subnet"
    }

  }

  egress_rules = {
    all = {
      cidr_ipv4   = "0.0.0.0/0"
      ip_protocol = "-1"
    }
  }

  tags = {
    Name = "devops-private-sg"
  }
}