resource "aws_redshift_subnet_group" "redshift" {
  name       = "wsi-redshift-subnets"
  subnet_ids = [
    aws_subnet.private_a.id
  ]
}

resource "random_password" "redshift_pass" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_security_group" "redshift" {
  name = "skills-redshift-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    protocol = "-1"
    from_port = "0"
    to_port = "0"
    self = true
  }

  egress {
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = "0"
    to_port = "0"
  }
}

resource "aws_secretsmanager_secret" "redshift" {
  name_prefix = "wsi-redshift-secret-"
}

resource "aws_secretsmanager_secret_version" "redshift" {
  secret_id     = aws_secretsmanager_secret.redshift.id
  secret_string = jsonencode({
    "username" = aws_redshift_cluster.redshift.master_username
    "password" = random_password.redshift_pass.result
  })
}

resource "aws_redshift_cluster" "redshift" {
  cluster_identifier = "wsi-redshift-cluster"
  database_name      = "wsi"
  master_username    = "wsi"
  master_password    = random_password.redshift_pass.result
  node_type          = "dc2.large"
  cluster_type       = "single-node"
  skip_final_snapshot = true
  publicly_accessible = false
  cluster_subnet_group_name = aws_redshift_subnet_group.redshift.name
  vpc_security_group_ids = [
    aws_security_group.redshift.id
  ]
}
