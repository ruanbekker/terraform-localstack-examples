resource "aws_elasticsearch_domain" "example" {
  domain_name           = "example"
  elasticsearch_version = "7.10"

  cluster_config {
    instance_type = "r4.large.elasticsearch"
  }

  tags = {
    Domain = "TestDomain"
  }
}
