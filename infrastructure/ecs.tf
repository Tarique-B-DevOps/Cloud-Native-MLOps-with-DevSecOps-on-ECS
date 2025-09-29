resource "aws_ecs_cluster" "cluster" {

  name = local.resource_prefix


}

resource "aws_ecs_cluster_capacity_providers" "fargate" {
  cluster_name = aws_ecs_cluster.cluster.name
  capacity_providers = [
    "FARGATE"
  ]
}