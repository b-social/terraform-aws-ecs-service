data "template_file" "service" {
  template = coalesce(var.service_task_container_definitions, file("${path.module}/container-definitions/service.json.tpl"))

  vars = {
    name = var.service_name
    image = var.service_image
    command = jsonencode(var.service_command)
    port = var.service_port
    region = var.region
    log_group = aws_cloudwatch_log_group.service.name
  }
}

resource "aws_ecs_task_definition" "service" {
  family = "${var.component}-${var.service_name}-${var.deployment_identifier}"
  container_definitions = data.template_file.service.rendered

  network_mode = var.service_task_network_mode

  task_role_arn = var.service_role

  volume {
    name = var.volume_name
    docker_volume_configuration {
      scope         = "shared"
      autoprovision = true
      driver        = "rexray/ebs"
      driver_opts = {
        volumetype = "gp2"
        size       = 1000
      }
    }
  }
}
