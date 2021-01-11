# security group
resource "aws_security_group" "metastore-rds" {
  name        = "isthari-${var.shortId}-metastore-rds"
  description = "Metastore DB"
  vpc_id      = aws_vpc.default.id
  tags = {
    Name = "isthari-${var.shortId}-metastore-rds"
  }
}

# subnet group
resource "aws_db_subnet_group" "default" {
  name = "isthari-${var.shortId}"
  subnet_ids = [ aws_subnet.private-1.id, aws_subnet.private-2.id ]
  tags = { 
    Name = "isthari-${var.shortId}"
  }
}

# cluster
resource "aws_rds_cluster" "metastore" {
  cluster_identifier        = "isthari-${var.shortId}-metastore"
  final_snapshot_identifier = "isthari-${var.shortId}-metastore"
  engine                    = "aurora-mysql"
  engine_mode               = "serverless"
  engine_version            = "5.7.mysql_aurora.2.07.1"
  availability_zones        = [ "${var.region}a", "${var.region}b" ]
  database_name             = "metastore"
  master_username           = "metastore"
  master_password           = var.metastorePassword 
  backup_retention_period   = 5
  deletion_protection       = false
  preferred_backup_window   = "07:00-09:00"
  scaling_configuration { 
    auto_pause               = true
    max_capacity             = 16
    min_capacity             = 1
    seconds_until_auto_pause = 300
    timeout_action           = "ForceApplyCapacityChange"
  }

  vpc_security_group_ids = [aws_security_group.metastore-rds.id]
  db_subnet_group_name   = aws_db_subnet_group.default.name

  lifecycle {
    ignore_changes = [
      availability_zones,
    ]
  }
}
