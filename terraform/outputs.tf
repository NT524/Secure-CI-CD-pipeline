output "cluster_endpoint" {
  description = "The endpoint of the EKS cluster"
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "The security group ID of the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

data "aws_region" "current" {}

output "aws_region" {
  description = "The AWS region where resources are deployed"
  value       = data.aws_region.current.name
}

output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = local.cluster_name
}

output "node_group_arns" {
  description = "ARNs of the EKS managed node groups"
  value       = [for group in module.eks.eks_managed_node_groups : group.node_group_arn]
}

output "node_group_ids" {
    description = "IDs of the EKS managed node groups"
    value       = [for group in module.eks.eks_managed_node_groups : group.node_group_id]
}

output "vpc_id" {
    description = "The ID of the VPC where the EKS cluster is deployed"
    value       = module.vpc.vpc_id
}

output "private_subnets" {
    description = "IDs of the private subnets used by the EKS cluster"
    value       = module.vpc.private_subnets
}

output "public_subnets" {
    description = "IDs of the public subnets used by the EKS cluster"
    value       = module.vpc.public_subnets
}