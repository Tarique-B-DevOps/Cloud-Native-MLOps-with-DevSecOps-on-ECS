output "ecr_repo_name" {
  value = aws_ecr_repository.repo.name

}

output "ecr_repo_arn" {
  value = aws_ecr_repository.repo.arn

}

output "ecr_repo_url" {
  value = aws_ecr_repository.repo.repository_url

}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.cluster.name

}

output "ecs_service_name" {
  value = aws_ecs_service.app_service.name

}

output "alb_dns" {
  value = aws_lb.alb.dns_name

}

output "api_endpoint" {
  value = aws_apigatewayv2_stage.stage.invoke_url

}

output "region" {
  value = aws_ecs_cluster.cluster.region

}

output "s3_bucket_name" {
  value = aws_s3_bucket.website.id

}

output "frontend_url" {
  value = "https://${aws_cloudfront_distribution.web_distro.domain_name}"

}