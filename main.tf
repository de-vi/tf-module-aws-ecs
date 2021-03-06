
/*
 * Create ECS IAM Service Role and Policy
 */
resource "aws_iam_role" "service_role" {
  name               = format("%s-%s", var.name, "service")
  assume_role_policy = file("${path.module}/ecs_service_role_assume_role_policy.json")
}

resource "aws_iam_role_policy" "service_role_policy" {
  name   = format("%s-%s", var.name, "service")
  role   = aws_iam_role.service_role.id
  policy = file("${path.module}/ecs_service_role_policy.json")
}

resource "aws_ecs_cluster" "ecs_cluster" {
  name = var.name
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_task_definition" "task_def" {
  family                = var.name
  network_mode          = "bridge"
  container_definitions = var.container_definitions
}

resource "aws_ecs_service" "app" {
  name            = var.name
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.task_def.arn
  desired_count   = var.desired_task_count
  iam_role        = aws_iam_role.service_role.arn
  depends_on      = [aws_iam_role_policy.service_role_policy]

  load_balancer {
    target_group_arn = var.alb_target_group_arn
    container_name   = var.container_name
    container_port   = var.container_port
  }
}
