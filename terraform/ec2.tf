data "aws_ami" "my_ami" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

data "aws_ssm_parameter" "token" {
  name = "/devops-bootcamp-2026/tunnel-token"
}

# < bersambung
module "node1" {
  source                 = "terraform-aws-modules/ec2-instance/aws"
  version                = "~> 6.0"
  name                   = "node1"
  ami                    = data.aws_ami.my_ami.id
  instance_type          = "t3.micro"
  subnet_id              = module.my_vpc.public_subnets[0]
  private_ip             = "10.0.0.5"
  create_security_group  = false
  vpc_security_group_ids = [module.public_sg.id]
  #  key_name               = "fareez-key"
  tags                 = { Name = "webserver" }
  root_block_device    = { size = 16 }
  iam_instance_profile = aws_iam_instance_profile.webserver.name
  #user_data            = templatefile("userdata-nginx.sh", {})
}

resource "aws_eip" "node1" {
  domain = "vpc"

  tags = {
    Name = "devops-web-eip"
  }
}

resource "aws_eip_association" "node1" {
  allocation_id = aws_eip.node1.id
  instance_id   = module.node1.id
}

module "node2" {
  source                 = "terraform-aws-modules/ec2-instance/aws"
  version                = "~> 6.0"
  name                   = "node2"
  ami                    = data.aws_ami.my_ami.id
  instance_type          = "t3.small"
  subnet_id              = module.my_vpc.private_subnets[0]
  private_ip             = "10.0.0.135"
  create_security_group  = false
  vpc_security_group_ids = [module.private_sg.id]
  #  key_name               = "fareez-key"
  tags                 = { Name = "ansible" }
  root_block_device    = { size = 16 }
  iam_instance_profile = aws_iam_instance_profile.ansible.name
  user_data            = templatefile("userdata-ansible.sh", {})
}


module "node3" {
  source                 = "terraform-aws-modules/ec2-instance/aws"
  version                = "~> 6.0"
  name                   = "node3"
  ami                    = data.aws_ami.my_ami.id
  instance_type          = "t3.small"
  subnet_id              = module.my_vpc.private_subnets[0]
  private_ip             = "10.0.0.136"
  create_security_group  = false
  vpc_security_group_ids = [module.private_sg.id]
  #  key_name               = "fareez-key"
  tags                 = { Name = "monitoring" }
  root_block_device    = { size = 16 }
  iam_instance_profile = aws_iam_instance_profile.monitoring.name
  user_data = templatefile("userdata-tunnel.sh", {
    tunnel_token = data.aws_ssm_parameter.token.value
  })
}