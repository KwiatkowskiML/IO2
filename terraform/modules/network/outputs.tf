output "vpc_id" { value = aws_vpc.this.id }
output "public_subnet_ids" { value = [for s in aws_subnet.public : s.id] }
output "private_subnet_ids" { value = [for s in aws_subnet.private : s.id] }
output "alb_security_group_id" { value = aws_security_group.alb_sg.id }
output "ecs_security_group_id" { value = aws_security_group.ecs_sg.id }
output "rds_security_group_id" { value = aws_security_group.rds_sg.id }
