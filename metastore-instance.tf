resource "aws_security_group" "metastore-instance" {
  name        = "isthari-${var.shortId}-metastore-instance"
  description = "Metastore server"
  vpc_id      = aws_vpc.default.id
  tags = {
    Name = "isthari-${var.shortId}-metastore-instance"
  }
}

resource "aws_security_group_rule" "metastore-instance-egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.metastore-instance.id
}

resource "aws_security_group_rule" "metastore-instance-to-db" {
  description              = "Metastore instance to db"
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.metastore-rds.id
  source_security_group_id = aws_security_group.metastore-instance.id
}

resource "aws_security_group_rule" "metastore-bigdata" {
  description              = "Access to metastore"
  type                     = "ingress"
  from_port                = "9083"
  to_port                  = "9083"
  protocol                 = "tcp"
  security_group_id        = aws_security_group.metastore-instance.id
  source_security_group_id = aws_security_group.instance.id
}

resource "aws_instance" "metastore" {
  ami                         = var.metastore-image[var.region]
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.private-1.id
  vpc_security_group_ids      = [ aws_security_group.metastore-instance.id ]
  iam_instance_profile        = aws_iam_instance_profile.instance.id
  associate_public_ip_address = false
  monitoring                  = false
  key_name                    = var.keyPair
  user_data                   = base64encode(local.metastore-script)
  tags = {
    Name = "isthari-${var.shortId}-metastore"
  }
  depends_on = [ aws_rds_cluster.metastore ] 
}

locals {
  metastore-script = <<EOT
Content-Type: multipart/mixed; boundary="//"
MIME-Version: 1.0

--//
Content-Type: text/cloud-config; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="cloud-config.txt"

#cloud-config
cloud_final_modules:
- [scripts-user, always]

--//
Content-Type: text/x-shellscript; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="userdata.txt"

#!/bin/sh
SHORT_ID=${var.shortId}
DB_HOST=metastore-db.$SHORT_ID.cloud.isthari.com
DB_DATABASE=metastore
DB_USERNAME=metastore
DB_PASSWORD=${var.metastorePassword}
BUCKET=${var.bucket}

export HADOOP_HOME=/usr/local/share/hadoop
export JAVA_HOME=/usr

sed -i 's/$STORAGE/'"$BUCKET"'/g' /usr/local/share/apache-hive/conf/core-site.xml

RESULT=`mysqlshow --user=$DB_USERNAME --password=$DB_PASSWORD metastore -h $DB_HOST | wc -l`
if [ $RESULT -ne 62 ]; then    
  echo "Create database"
  cd /usr/local/share/metastore-schema
  mysql -u $DB_USERNAME -p$DB_PASSWORD -h $DB_HOST $DB_DATABASE < hive-schema-2.3.0.mysql.sql    
fi
    
/usr/local/share/apache-hive/bin/hive --service metastore --hiveconf javax.jdo.option.ConnectionURL=jdbc:mysql://$DB_HOST/$DB_DATABASE?createDatabaseIfNotExist=true --hiveconf javax.jdo.option.ConnectionUserName=$DB_USERNAME --hiveconf javax.jdo.option.ConnectionPassword=$DB_PASSWORD
EOT
}
