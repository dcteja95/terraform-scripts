resource "aws_security_group" "workload" {
  name        = "${var.name_prefix}-workload-sg"
  description = "Private workload security group"
  vpc_id      = var.vpc_id
  egress {
    description = "Allow HTTPS egress for AWS API calls and package downloads"
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(var.tags, { Name = "${var.name_prefix}-workload-sg" })
}

