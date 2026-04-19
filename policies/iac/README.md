# README

## Learnings

- [BDD Reference](https://terraform-compliance.com/pages/bdd-references/given.html)

Given
When
...
Then
...

-----

Given I have azurerm_postgresql_server defined
When its auto_grow_enabled is true

-----

Scenario: Example scenario
  Given I have any resource defined
    Then its type must be aws_flow_log

-----

resource "aws_s3_bucket" "my-bucket" {
  bucket = "some-bucket-name"
  acl    = "private"

  ...
}

can be written as ;

Feature: My test feature

Scenario: Ensure my specific s3 buckets are private
  Given I have aws_s3_bucket defined
  Then it must contain acl
  And its value must be private

=>

Feature: My test feature

Scenario: Ensure my specific s3 buckets are private
  Given I have AWS S3 Bucket defined
  Then it must contain acl
  And its value must be private

-----

- [terraform-compliance tags (scenario decorators](https://terraform-compliance.com/pages/bdd-references/using_tags.html)

-----

[user-friendly-features](https://github.com/terraform-compliance/user-friendly-features)

git clone https://github.com/terraform-compliance/user-friendly-features.git ./terraform-compliance/user-friendly-features

cd ~/Projects/gitlab.kazan.myworldline.com/cicd/terraform/deployments/terraform/aws/worldline-gc-cicd-build-prod/eu-west-1/toolbox/m590
onelogin -C [[REDACTED]]

terraform plan -out=plan.out
terraform show -json plan.out > plan.out.json
# if the value from --features is missing then it is copied from $HOME/.terraform-compliance/user-friendly-features to local dir
terraform-compliance \
  --features .terraform-compliance/user-friendly-features/aws \
  --planfile plan.out.json
```
