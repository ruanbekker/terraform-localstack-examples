# elasticsearch-example

Terraform with Localstack example to provision a Elasticsearch cluster.

## Usage

Deploy localstack:

```bash
pushd ../
make up
popd
```

Deploy infrastructure:

```bash
terraform init
terraform apply -auto-approve
```

Describe elasticsearch domain:

```bash
aws --endpoint-url=http://localhost:4566 --region=eu-west-1 es describe-elasticsearch-domain --domain-name example
```

From the response retreve the endpoint:

```json
{
    "DomainStatus": {
        "DomainId": "000000000000/example",
        "DomainName": "example",
        "ARN": "arn:aws:es:eu-west-1:000000000000:domain/example",
        "Created": true,
        "Endpoint": "example.eu-west-1.es.localhost.localstack.cloud:4566",
        "Processing": false,
        "UpgradeProcessing": false,
        "ElasticsearchVersion": "7.10",
        "ElasticsearchClusterConfig": { },
    }
}
```

Make a request:

```bash
curl http://example.eu-west-1.es.localhost.localstack.cloud:4566
{
  "name" : "fe57a1e2a847",
  "cluster_name" : "elasticsearch",
  "cluster_uuid" : "dooV7r_KRDmUsCf26sNMtA",
  "version" : {
    "number" : "7.10.0",
    "build_flavor" : "default",
    "build_type" : "tar",
    "build_hash" : "51e9d6f22758d0374a0f3f5c6e8f3a7997850f96",
    "build_date" : "2020-11-09T21:30:33.964949Z",
    "build_snapshot" : false,
    "lucene_version" : "8.7.0",
    "minimum_wire_compatibility_version" : "6.8.0",
    "minimum_index_compatibility_version" : "6.0.0-beta1"
  },
  "tagline" : "You Know, for Search"
}
```

Create a elasticsearch index:

```bash
curl -XPUT -H "Content-Type: application/json" http://example.eu-west-1.es.localhost.localstack.cloud:4566/test-index
{"acknowledged":true,"shards_acknowledged":true,"index":"test-index"}
```

View indices:

```bash
curl 'http://example.eu-west-1.es.localhost.localstack.cloud:4566/_cat/indices?v'
health status index      uuid                   pri rep docs.count docs.deleted store.size pri.store.size
yellow open   test-index geUorQvpSxWwK5XXQUwXgQ   1   1          0            0       208b           208b
```
