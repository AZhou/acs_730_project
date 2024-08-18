output "public_subnet_ids" {
  value = module.vpc-prod.subnet_id
}

output "number_of_public_subnet_ids" {
  value = length(module.vpc-prod.subnet_id)
}

output "vpc_id" {
  value = module.vpc-prod.vpc_id
}


output "private_subnet_ids" {
  value = module.vpc-prod.private_subnet_id
}

output "number_of_private_subnet_ids" {
  value = length(module.vpc-prod.private_subnet_id)
}