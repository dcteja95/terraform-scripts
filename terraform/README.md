# Terraform

The root Terraform implementation is split into three reusable domain modules:

- `modules/infrastructure` - shared AWS foundation, security, logging, monitoring and cost controls.
- `modules/data-collection` - ingestion, Glue ETL/catalog, Athena and validation.
- `modules/mlops` - SageMaker, training, model registry, endpoint and inference observability.

`environments/prod` composes the modules and supplies environment-specific configuration.

## Naming

AWS service resources follow `<environment>-<project>-<service>`, for example `prod-bmw-vpc` and `prod-bmw-cloudtrail`.

## Tags

The common tags are exactly:

```text
Project=bmw
Team=developer
Environment=prod
```

## Validation

```bash
terraform fmt -recursive
terraform init -backend=false
terraform validate
```
