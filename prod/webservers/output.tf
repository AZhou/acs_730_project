output "public_ip" {
  value = [for instance in aws_instance.web_test_public : instance.public_ip]
}

output "private_ip" {
  value = [for instance in aws_instance.web_test_private : instance.private_ip]
}
output "web_eip" {
  value = [for instance in aws_eip.static_eip : instance.public_ip]
}
# Output the Load Balancer DNS Name
output "alb_dns_name" {
  description = "The DNS name of the load balancer"
  value       = aws_lb.web_alb.dns_name
}
