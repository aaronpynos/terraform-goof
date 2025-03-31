
# 🔓 Security group with unrestricted access
resource "aws_security_group" "wide_open" {
  name        = "wide-open-sg"
  description = "SG with open ingress"

  ingress {
    description = "All TCP from anywhere"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#  Public S3 Bucket (modern misconfiguration)
resource "aws_s3_bucket" "public_bucket" {
  bucket        = "vulnerable-modern-public-bucket"
  force_destroy = true
}

#Disabling public access block (BAD)
resource "aws_s3_bucket_public_access_block" "disabled" {
  bucket = aws_s3_bucket.public_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# 🔑 Exposed SSH key resource
resource "tls_private_key" "exposed_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "insecure_key" {
  key_name   = "my-key"
  public_key = tls_private_key.exposed_key.public_key_openssh
}


# EC2 instance — Hardcoded AWS creds + unencrypted volume
resource "aws_instance" "exposed_ec2" {
  ami                    = "ami-0005e0cfe09cc9050"
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.insecure_key.key_name
  vpc_security_group_ids = [aws_security_group.wide_open.id]

  user_data = <<-EOF
              #!/bin/bash
              echo "export AWS_ACCESS_KEY_ID=AKIA1234567890EXAMPLE" >> /etc/profile
              echo "export AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY" >> /etc/profile
              EOF

  root_block_device {
    volume_size = 8
    volume_type = "gp2"
    encrypted   = false
  }

  tags = {
    Name = "vulnerable-ec2-instance"
  }
}

#  2. Hardcoded AWS credentials 
variable "aws_access_key" {
  default = "AKIA1234567890EXAMPLE"
}

variable "aws_secret_key" {
  default = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
}
