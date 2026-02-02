# EFS File System
resource "aws_efs_file_system" "flux" {
  creation_token = "flux-efs"
  encrypted      = true
  
  tags = {
    Name = "${var.cluster_name}-efs"
  }
}

# EFS Mount Targets (connects EFS to VPC subnets)
resource "aws_efs_mount_target" "flux" {
  count           = length(module.vpc.private_subnets)
  file_system_id  = aws_efs_file_system.flux.id
  subnet_id       = module.vpc.private_subnets[count.index]
  security_groups = [aws_security_group.efs.id]
}

# Security Group for EFS
resource "aws_security_group" "efs" {
  name        = "${var.cluster_name}-efs-sg"
  description = "Allow NFS traffic from EKS nodes"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "NFS from EKS nodes"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [module.eks.node_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-efs-sg"
  }
}
