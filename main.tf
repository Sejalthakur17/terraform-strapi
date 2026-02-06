
# VPC
resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "${var.environment}-vpc"
  }
}

# Subnets

# Public Subnet (ALB + NAT)
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.public_subnet_cidr
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}a"

  tags = {
    Name = "${var.environment}-public-subnet"
  }
}
# Second Public Subnet (Required for ALB)
resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.3.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}b"

  tags = {
    Name = "${var.environment}-public-subnet-2"
  }
}

# Private Subnet (EC2)
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "${var.environment}-private-subnet"
  }
}

# Internet Gateway

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.environment}-igw"
  }
}

# NAT Gateway

resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "${var.environment}-nat"
  }
}

# Route Tables

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.environment}-public-rt"
  }
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}
# Public Route Table Association (Subnet 1)
resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}


# Private Route Table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "${var.environment}-private-rt"
  }
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# Security Groups

# ALB Security Group
resource "aws_security_group" "alb_sg" {
  name   = "${var.environment}-alb-sg"
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# EC2 Security Group
resource "aws_security_group" "ec2_sg" {
  name   = "${var.environment}-ec2-sg"
  vpc_id = aws_vpc.vpc.id


  ingress {
    from_port       = 1337
    to_port         = 1337
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  }
 

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

# EC2 (Private)

resource "aws_instance" "strapi" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  key_name               = var.key_name

  tags = {
    Name = "main-strapi"
  }
}



# Application Load Balancer

resource "aws_lb" "alb" {
  name               = "${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets = [
  aws_subnet.public.id,
  aws_subnet.public_2.id
]
}

resource "aws_lb_target_group" "tg" {
  name     = "main-tg"
  port     = 1337
  protocol = "HTTP"
  vpc_id = aws_vpc.vpc.id

  health_check {
    path    = "/"
    matcher = "200-399"
  }
}




resource "aws_lb_target_group_attachment" "attach" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.strapi.id
  port             = 1337
}

#resource "aws_lb_listener" "listener" {
 # load_balancer_arn = aws_lb.alb.arn
  #port              = 80
  #protocol          = "HTTP"

  #default_action {
   # type             = "forward"
    #target_group_arn = aws_lb_target_group.tg.arn
# }
#}
