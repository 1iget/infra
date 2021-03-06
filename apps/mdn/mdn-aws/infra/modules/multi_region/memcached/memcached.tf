
variable "memcached_name" {}
variable "memcached_node_size" {}

variable "memcached_port" {
    default=11121
}

variable "memcached_num_nodes" {
    default=1
}

variable "memcached_param_group" {
    default="default.memcached1.4"
}

variable "memcached_engine_version" {
    default="1.4.34"
}

variable "subnets" {}
variable "nodes_security_group" {
  type = "list"
}

variable "enabled" {}

variable "environment" {}

variable "region" {}

provider "aws" {
  region  = "${var.region}"
}

resource "aws_elasticache_subnet_group" "mdn-memcached-subnet-group" {
  count = "${var.enabled}"

  name       = "mdn-memcached-${var.memcached_name}-subnet-group"
  # https://github.com/hashicorp/terraform/issues/57#issuecomment-100372002
  subnet_ids = ["${split(",", var.subnets)}"]
}

resource "aws_elasticache_cluster" "mdn-memcached" {
  count = "${var.enabled}"

  cluster_id           = "mdn-memcached-${var.memcached_name}"
  engine               = "memcached"
  node_type            = "${var.memcached_node_size}"
  port                 = "${var.memcached_port}"
  num_cache_nodes      = "${var.memcached_num_nodes}"
  parameter_group_name = "${var.memcached_param_group}"
  engine_version       = "${var.memcached_engine_version}"
  subnet_group_name    = "${aws_elasticache_subnet_group.mdn-memcached-subnet-group.name}"
  security_group_ids   = [ "${var.nodes_security_group}" ]

  tags {
    Name        = "MDN-${var.memcached_name}-${var.environment}"
    Stack       = "MDN-${var.memcached_name}"
    Environment = "${var.environment}"
    Region      = "${var.region}"
  }
}

output memcached_endpoint {
  value = "${element(concat(aws_elasticache_cluster.mdn-memcached.*.configuration_endpoint, list("")), 0)}"
}
