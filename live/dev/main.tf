module "vpc" {
  source = "../../modules/vpc"

  project_name       = var.project_name
  cidr_block         = "11.0.0.0/16"
  enable_nat_gateway = true
  public_subnets     = ["11.0.1.0/24", "11.0.2.0/24", "11.0.3.0/24"]
  private_subnets    = ["11.0.4.0/24", "11.0.5.0/24", "11.0.6.0/24"]
  frontend_subnets   = ["11.0.7.0/24", "11.0.8.0/24", "11.0.9.0/24"]
  backend_subnets    = ["11.0.10.0/24", "11.0.11.0/24", "11.0.12.0/24"]
  database_subnets   = ["11.0.13.0/24", "11.0.14.0/24", "11.0.15.0/24"]
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
  environment        = var.environment
}

module "asg" {
  source = "../../modules/asg"

  name             = "mix"
  subnet_ids       = module.vpc.public_sub_ids
  instance_type    = "t3.micro"
  desired_capacity = 1
  max_size         = 2
  min_size         = 1
  security_groups  = [module.vpc.asg_sg_id]
  project_name     = var.project_name
  environment      = var.environment
}

module "ecs_cluster" {
  source = "../../modules/ecs/cluster"

  auto_scaling_groups = {
    mix = {
      name            = "mix"
      arn             = module.asg.arn
      target_capacity = 100
    }
  }
  project_name = var.project_name
  environment  = var.environment
}


module "alb" {
  source = "../../modules/alb"

  name            = "mix"
  project_name    = var.project_name
  environment     = var.environment
  vpc_id          = module.vpc.id
  subnet_ids      = module.vpc.public_sub_ids
  security_groups = [module.vpc.frontend_alb_sg_id, module.vpc.backend_alb_sg_id]

  target_groups = {
    frontend = {
      name              = "frontend"
      port              = 80
      protocol          = "HTTP"
      target_type       = "ip"
      health_check_path = "/"
    }
    backend = {
      name              = "backend"
      port              = 80
      protocol          = "HTTP"
      target_type       = "ip"
      health_check_path = "/health"
    }
  }

  listener = {
    name             = "frontend"
    target_group_key = "frontend"
    rules = {
      backend = {
        description      = "forward traffic to APIs"
        target_group_key = "backend"
        patterns         = ["/api/*"]
      }
    }
  }
}


module "frontend_ecr" {
  source = "../../modules/ecr"

  name         = "frontend"
  project_name = var.project_name
  environment  = var.environment
}

module "frontend_task" {
  source = "../../modules/ecs/task"

  project_name = var.project_name
  environment  = var.environment
  family       = "frontend"
  cpu          = "256"
  memory       = "112"
  containers = [
    {
      name      = "frontend"
      image     = "nginx:latest"
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
    }
  ]
}

module "frontend_service" {
  source = "../../modules/ecs/service"

  name             = "frontend"
  ecs_cluster_name = module.ecs_cluster.name
  ecs_cluster_id   = module.ecs_cluster.id

  container_name      = "frontend"
  task_definition_arn = module.frontend_task.arn
  alb_blue_tg_arn     = module.alb.blue_tg["frontend"].arn
  security_groups     = [module.vpc.frontend_sg_id]
  subnet_ids          = module.vpc.frontend_sub_ids
  container_port      = 80
  project_name        = var.project_name
  environment         = var.environment
}




module "backend_ecr" {
  source = "../../modules/ecr"

  name         = "backend"
  project_name = var.project_name
  environment  = var.environment
}

module "backend_task" {
  source = "../../modules/ecs/task"

  project_name = var.project_name
  environment  = var.environment
  family       = "backend"
  cpu          = "1024"
  memory       = "512"
  containers = [
    {
      name      = "backend"
      image     = "nginx:latest"
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
    }
  ]
}


module "backend_service" {
  source = "../../modules/ecs/service"

  name             = "backend"
  ecs_cluster_name = module.ecs_cluster.name
  ecs_cluster_id   = module.ecs_cluster.id

  container_name      = "backend"
  task_definition_arn = module.backend_task.arn
  alb_blue_tg_arn     = module.alb.blue_tg["backend"].arn
  security_groups     = [module.vpc.backend_sg_id]
  subnet_ids          = module.vpc.backend_sub_ids
  container_port      = 80
  project_name        = var.project_name
  environment         = var.environment
}