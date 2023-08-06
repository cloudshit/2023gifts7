resource "aws_security_group" "app" {
  name = "skills-app-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = "22"
    to_port = "22"
  }

  ingress {
    protocol = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
    from_port = "8080"
    to_port = "8080"
  }

  egress {
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = "0"
    to_port = "0"
  }
}

resource "aws_iam_role" "app" {
  name = "skills-role-app"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  managed_policy_arns = ["arn:aws:iam::aws:policy/AdministratorAccess"]
}

resource "aws_iam_instance_profile" "app" {
  name = "skills-profile-app"
  role = aws_iam_role.app.name
}

resource "aws_instance" "app" {
  instance_type = "c5.large"
  subnet_id = aws_subnet.private_a.id
  vpc_security_group_ids = [aws_security_group.app.id]
  iam_instance_profile = aws_iam_instance_profile.app.name
  key_name = aws_key_pair.keypair.key_name
  
  ami = "ami-0b7c737f668580ff1"

  tags = {
    Name = "skills-app"
  }
}
