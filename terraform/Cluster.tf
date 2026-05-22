# 1. TRUY VẤN SECURITY GROUP ĐÃ CÓ SẴN TRÊN AWS (DATA SOURCE)
# Lệnh này bảo Terraform: "Lên AWS, tìm cái Security Group nào có tên là 'nodegoat-staging-sg' mang về đây"
# TẠO SECURITY GROUP (TƯỜNG LỬA CHO MÔI TRƯỜNG STAGING)
# resource "aws_security_group" "staging_sg" {
#   name        = "nodegoat-staging-sg"
#   description = "Allow inbound traffic for SSH and Web app"

#   # CỔNG 22 (SSH): Cho phép cấu hình từ xa.
#   ingress {
#     description = "Allow SSH from automation runner"
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     # tfsec:ignore:aws-ec2-no-public-ingress-sgr
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   # CỔNG 80 (HTTP WEB): Mở để OWASP ZAP kiểm thử DAST
#   ingress {
#     description = "Allow HTTP for public DAST scanning"
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     # tfsec:ignore:aws-ec2-no-public-ingress-sgr
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   # ĐƯỜNG RA (EGRESS): Cho phép máy chủ tải gói K3s và kéo Docker Image từ GHCR
#   egress {
#     description = "Allow all outbound traffic for updates and image pulls"
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     # tfsec:ignore:aws-ec2-no-public-egress-sgr
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

data "aws_security_group" "existing_sg" {
  name = "nodegoat-staging-sg"
}

# 2. TẠO MÁY ẢO EC2 THUỘC GÓI MIỄN PHÍ
resource "aws_instance" "staging_server" {
  ami           = "ami-0c7217cdde317cfec" # Ubuntu 22.04 LTS tại us-east-1
  instance_type = "t3.micro"             # Thuộc gói AWS Free Tier

  # 🌟 ĐÃ THAY ĐỔI: Tái sử dụng ID của Security Group vừa tìm được ở khối 'data' trên
  vpc_security_group_ids = [data.aws_security_group.existing_sg.id]
  key_name               = "nodegoat-staging-key"

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 8
    encrypted             = true
    delete_on_termination = true
  }

  user_data = <<-EOF
              #!/bin/bash
              echo "Hạ tầng thô khởi tạo thành công. Chờ Ansible cấu hình..."
              EOF

  tags = {
    Name        = "nodegoat-staging-free"
    Environment = "staging"
  }
}

# 3. XUẤT ĐỊA CHỈ IP CÔNG KHAI
output "staging_public_ip" {
  value       = aws_instance.staging_server.public_ip
  description = "IP công khai của môi trường AWS Staging"
}