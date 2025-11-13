# =====================
# 🌐 VPC + Subnet Setup
# ===================== 

# 🚧 Creates the main Virtual Private Cloud
resource "aws_vpc" "this" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc-${var.environment}"
  }
}

# 📦 Public Subnets 
resource "aws_subnet" "public" {
  count = length(var.public_subnets)

  vpc_id                  = aws_vpc.this.id
  availability_zone       = element(var.availability_zones, count.index)
  cidr_block              = element(var.public_subnets, count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-pub-sub-${element(var.availability_zones, count.index)}-${var.environment}"
  }
}

# 🔒 Private Subnets 
resource "aws_subnet" "private" {
  count = length(var.private_subnets)

  vpc_id            = aws_vpc.this.id
  availability_zone = element(var.availability_zones, count.index)
  cidr_block        = element(var.private_subnets, count.index)

  tags = {
    Name = "${var.project_name}-pvt-sub-${element(var.availability_zones, count.index)}-${var.environment}"
  }
}

resource "aws_subnet" "frontend" {
  count = length(var.frontend_subnets)

  vpc_id            = aws_vpc.this.id
  availability_zone = element(var.availability_zones, count.index)
  cidr_block        = element(var.frontend_subnets, count.index)

  tags = {
    Name = "${var.project_name}-frontend-pvt-sub-${element(var.availability_zones, count.index)}-${var.environment}"
  }
}

resource "aws_subnet" "asg" {
  count = length(var.asg_subnets)

  vpc_id            = aws_vpc.this.id
  availability_zone = element(var.availability_zones, count.index)
  cidr_block        = element(var.asg_subnets, count.index)

  tags = {
    Name = "${var.project_name}-asg-pvt-sub-${element(var.availability_zones, count.index)}-${var.environment}"
  }
}

resource "aws_subnet" "backend" {
  count = length(var.backend_subnets)

  vpc_id            = aws_vpc.this.id
  availability_zone = element(var.availability_zones, count.index)
  cidr_block        = element(var.backend_subnets, count.index)

  tags = {
    Name = "${var.project_name}-backend-pvt-sub-${element(var.availability_zones, count.index)}-${var.environment}"
  }
}

resource "aws_subnet" "database" {
  count = length(var.backend_subnets)

  vpc_id            = aws_vpc.this.id
  availability_zone = element(var.availability_zones, count.index)
  cidr_block        = element(var.database_subnets, count.index)

  tags = {
    Name = "${var.project_name}-database-pvt-sub-${element(var.availability_zones, count.index)}-${var.environment}"
  }
}

# =========================
# 🌍 Internet Gateway Setup
# =========================

# 🌐 Internet Gateway for public subnets (1 per VPC)
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.project_name}-pvt-${var.environment}"
  }
}

# ====================
# 🚪 NAT Gateway Setup
# ====================

# 📤 Elastic IP for NAT Gateway
resource "aws_eip" "this" {
  count = var.enable_nat_gateway == true ? 1 : 0

  domain = "vpc"

  tags = {
    Name = "${var.project_name}-nat-gw-eip-${var.environment}"
  }
}

# 🔁 NAT Gateway for outbound traffic from private subnets
resource "aws_nat_gateway" "this" {
  count = var.enable_nat_gateway == true ? 1 : 0

  subnet_id     = aws_subnet.public[0].id
  allocation_id = aws_eip.this[0].id

  tags = {
    Name = "${var.project_name}-nat-gw-${var.environment}"
  }
}

# =========================
# 🛣️ Route Tables & Routing
# =========================

# 🛣️ Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "${var.project_name}-pub-rt-${var.environment}"
  }
}

# 🔒 Private Route Table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  dynamic "route" {
    for_each = var.enable_nat_gateway == true ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.this[0].id
    }
  }

  tags = {
    Name = "${var.project_name}-pvt-rt-${var.environment}"
  }
}

# ===========================
# 🔗 Route Table Associations
# ===========================

# 🔗 Associate public subnets with public route table
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.public[count.index].id
}

# 🔗 Associate private subnets with private route table
resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)

  route_table_id = aws_route_table.private.id
  subnet_id      = aws_subnet.private[count.index].id
}

# 🔗 Associate private subnets with private route table
resource "aws_route_table_association" "asg" {
  count = length(aws_subnet.asg)

  route_table_id = aws_route_table.private.id
  subnet_id      = aws_subnet.asg[count.index].id
}

# 🔗 Associate private subnets with private route table
resource "aws_route_table_association" "frontend" {
  count = length(aws_subnet.frontend)

  route_table_id = aws_route_table.private.id
  subnet_id      = aws_subnet.frontend[count.index].id
}

# 🔗 Associate private subnets with private route table
resource "aws_route_table_association" "backend" {
  count = length(aws_subnet.backend)

  route_table_id = aws_route_table.private.id
  subnet_id      = aws_subnet.backend[count.index].id
}

# 🔗 Associate private subnets with private route table
resource "aws_route_table_association" "database" {
  count = length(aws_subnet.database)

  route_table_id = aws_route_table.private.id
  subnet_id      = aws_subnet.database[count.index].id
}

# ==================
# 🔐 Security Groups 
# ==================

resource "aws_security_group" "frontend_alb" {
  name = "${var.project_name}-frontend-alb-sg-${var.environment}"

  vpc_id = aws_vpc.this.id

  ingress {
    description = "Allow HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-frontend-alb-sg-${var.environment}"
  }
}

resource "aws_security_group" "backend_alb" {
  name = "${var.project_name}-backend-alb-sg-${var.environment}"

  vpc_id = aws_vpc.this.id

  ingress {
    description = "Allow HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-backend-alb-sg-${var.environment}"
  }
}

resource "aws_security_group" "frontend" {
  name   = "${var.project_name}-frontend-sg-${var.environment}"
  vpc_id = aws_vpc.this.id

  ingress {
    description     = "Allow HTTP"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend_alb.id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-alb-sg-${var.environment}"
  }
}

resource "aws_security_group" "backend" {
  name   = "${var.project_name}-backend-sg-${var.environment}"
  vpc_id = aws_vpc.this.id

  ingress {
    description     = "Allow HTTP"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.backend_alb.id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-backend-sg-${var.environment}"
  }
}

# ===========================================================
# 🔍 Fetch public IP of current machine (used for SSH access)
# ===========================================================
data "http" "my_ip" {
  url = "https://api.ipify.org"
}

resource "aws_security_group" "asg" {
  name = "${var.project_name}-asg-sg-${var.environment}"

  vpc_id = aws_vpc.this.id

  ingress {
    description     = "Allow HTTPS"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_ec2.id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-docdb-sg-${var.environment}"
  }
}

resource "aws_security_group" "bastion_ec2" {
  name        = "${var.project_name}-bastion-ec2-sg-${var.environment}"
  description = "Allow SSH and HTTP"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.my_ip.response_body)}/32"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-bastion-ec2-sg-${var.environment}"
  }
}

resource "aws_security_group" "docdb" {
  name = "${var.project_name}-docdb-sg-${var.environment}"

  vpc_id = aws_vpc.this.id

  ingress {
    description     = "Allow HTTPS"
    from_port       = 27017
    to_port         = 27017
    protocol        = "tcp"
    security_groups = [aws_security_group.backend.id, aws_security_group.bastion_ec2.id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-docdb-sg-${var.environment}"
  }
}
