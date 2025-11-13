# ===========================
# 📈 Auto Scaling Group (ASG)
# ===========================
resource "aws_autoscaling_group" "this" {
  name                      = "${var.project_name}-${var.name}-asg-${var.environment}"
  desired_capacity          = var.desired_capacity
  max_size                  = var.max_size
  min_size                  = var.min_size
  health_check_grace_period = 300
  health_check_type         = "EC2"
  placement_group           = aws_placement_group.this.id
  vpc_zone_identifier       = var.subnet_ids
  protect_from_scale_in     = var.ecs_cluster_name != null ? true : false

  metrics_granularity = "1Minute"

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances"
  ]

  lifecycle {
    ignore_changes = [tag]
  }

  launch_template {
    id      = aws_launch_template.this.id
    version = aws_launch_template.this.latest_version
  }
}

# ==================
# 🧱 Placement Group
# ==================
resource "aws_placement_group" "this" {
  name     = "${var.project_name}-${var.name}-pg-${var.environment}"
  strategy = "spread"
}

# ================================
# 🚀 Launch Template (used by ASG)
# ================================
resource "aws_launch_template" "this" {
  name          = "${var.project_name}-${var.name}-lt-${var.environment}"
  instance_type = var.instance_type
  image_id      = var.ecs_cluster_name != null ? data.aws_ami.al2023_ecs_kernel6plus.image_id : data.aws_ami.al2023_kernel6plus.image_id
  key_name      = aws_key_pair.this.key_name

  user_data = base64encode(var.ecs_cluster_name != null ? data.template_file.ecs_user_data[0].rendered : var.ecs_user_data)

  dynamic "iam_instance_profile" {
    for_each = var.ecs_cluster_name != null ? [1] : []
    content {
      name = aws_iam_instance_profile.this[0].name
    }
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = var.ebs_size
      volume_type           = var.ebs_type
      delete_on_termination = true
      encrypted             = true
    }
  }

  network_interfaces {
    security_groups = var.security_groups
  }

  tags = {
    Name = "${var.project_name}-${var.name}-lt-${var.environment}"
  }
}

# ========================
# 🔐 TLS Key Pair Creation
# ========================
resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "this" {
  key_name   = "${var.project_name}-${var.name}-key-${var.environment}"
  public_key = tls_private_key.this.public_key_openssh
}

resource "local_file" "this" {
  filename        = "${path.root}/keys/${aws_key_pair.this.key_name}.pem"
  content         = tls_private_key.this.private_key_openssh
  file_permission = "0600"
}

# =================================
# 🛡️ IAM Role + Profile for ECS EC2
# =================================
data "aws_iam_policy_document" "ecs_assume_role" {
  count = var.ecs_cluster_name != null ? 1 : 0

  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy" "ecs_ec2_role_policy" {
  count = var.ecs_cluster_name != null ? 1 : 0

  name = "AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role" "this" {
  count = var.ecs_cluster_name != null ? 1 : 0

  name               = "${var.project_name}-${var.name}-ecs-instance-role-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role[0].json

  tags = {
    Name = "${var.project_name}-${var.name}-ecs-instance-role-${var.environment}"
  }
}

resource "aws_iam_role_policy_attachment" "this" {
  count = var.ecs_cluster_name != null ? 1 : 0

  role       = aws_iam_role.this[0].name
  policy_arn = data.aws_iam_policy.ecs_ec2_role_policy[0].arn
}

resource "aws_iam_instance_profile" "this" {
  count = var.ecs_cluster_name != null ? 1 : 0

  name = "${var.project_name}-${var.name}-ecs-instance-profile-${var.environment}"
  role = aws_iam_role.this[0].name
  tags = {
    Name = "${var.project_name}-${var.name}-ecs-instance-profile-${var.environment}"
  }
}

# ==============================================
# 🧾 ECS Cluster Registration Script (User Data)
# ==============================================
data "template_file" "ecs_user_data" {
  count    = var.ecs_cluster_name != null ? 1 : 0
  template = file("${path.module}/scripts/ecs_cluster_registration.sh.tpl")
  vars = {
    ecs_cluster_name = var.ecs_cluster_name
  }
}

# =======================================
# 📦 Amazon Linux 2023 ECS Optimized AMIs
# =======================================
data "aws_ami" "al2023_ecs_kernel6plus" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-ecs-hvm-2023*-kernel-6*-x86_64"]
  }
  filter {
    name   = "state"
    values = ["available"]
  }
}

data "aws_ami" "al2023_kernel6plus" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023*-kernel-6*-x86_64"]
  }
  filter {
    name   = "state"
    values = ["available"]
  }
}