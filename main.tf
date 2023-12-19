resource "aws_db_instance" "main_rds_instance" {
  identifier        = "${var.rds_instance_identifier}"
  allocated_storage = "${var.rds_allocated_storage}"
  engine            = "${var.rds_engine_type}"
  engine_version    = "${var.rds_engine_version}"
  instance_class    = "${var.rds_instance_class}"
  name              = "${var.database_name}"
  username          = "${var.database_user}"
  password          = "${var.database_password}"

  port = "${var.database_port}"

  vpc_security_group_ids = ["${aws_security_group.main_db_access.id}"]

  db_subnet_group_name = "${aws_db_subnet_group.main_db_subnet_group.id}"
  parameter_group_name = "${var.use_external_parameter_group ? var.parameter_group_name : aws_db_parameter_group.main_rds_instance.id}"

  multi_az            = "${var.rds_is_multi_az}"
  storage_type        = "${var.rds_storage_type}"
  iops                = "${var.rds_iops}"
  publicly_accessible = "${var.publicly_accessible}"

  allow_major_version_upgrade = "${var.allow_major_version_upgrade}"
  auto_minor_version_upgrade  = "${var.auto_minor_version_upgrade}"
  apply_immediately           = "${var.apply_immediately}"
  maintenance_window          = "${var.maintenance_window}"

  skip_final_snapshot   = "${var.skip_final_snapshot}"
  copy_tags_to_snapshot = "${var.copy_tags_to_snapshot}"

  backup_retention_period = "${var.backup_retention_period}"
  backup_window           = "${var.backup_window}"

  monitoring_interval = "${var.monitoring_interval}"

  tags = "${merge(var.tags, map("Name", format("%s", var.rds_instance_identifier)))}"
}

resource "aws_db_parameter_group" "main_rds_instance" {
  count = "${var.use_external_parameter_group ? 0 : 1}"

  name   = "${var.rds_instance_identifier}-${replace(var.db_parameter_group, ".", "")}-custom-params"
  family = "${var.db_parameter_group}"

  tags = "${merge(var.tags, map("Name", format("%s", var.rds_instance_identifier)))}"
}

resource "aws_db_subnet_group" "main_db_subnet_group" {
  name        = "${var.rds_instance_identifier}-subnetgrp"
  description = "RDS subnet group"
  subnet_ids  = ["${var.subnets}"]

  tags = "${merge(var.tags, map("Name", format("%s", var.rds_instance_identifier)))}"
}

resource "aws_security_group" "main_db_access" {
  name        = "${var.rds_instance_identifier}-access"
  description = "Allow access to the database"
  vpc_id      = "${var.rds_vpc_id}"

  tags = "${merge(var.tags, map("Name", format("%s", var.rds_instance_identifier)))}"
}

resource "aws_security_group_rule" "allow_db_access" {
  type = "ingress"

  from_port   = "${var.database_port}"
  to_port     = "${var.database_port}"
  protocol    = "tcp"
  cidr_blocks = ["${var.private_cidr}"]

  security_group_id = "${aws_security_group.main_db_access.id}"
}

resource "aws_security_group_rule" "allow_all_outbound" {
  type = "egress"

  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.main_db_access.id}"
}
