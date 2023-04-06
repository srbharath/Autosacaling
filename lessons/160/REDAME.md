- start with plain code for vpc and multiple environments
- convert same code to modules
- convert to terragrunt
- run multiple terraform modules at once (vpc - eks)
- use iam role to create EKS and vpc


sources?
- modules
- plain terraform code
- do i have to create terraform module?
- follow the same quick start
- you should use it in large companies
- when you read this yes it's exactly what you need
- show example of DRY
- use cases - https://terragrunt.gruntwork.io/docs/#features
- we'll build the code and along the way learn all the features of terragrant and the end you'll get this
- do not create modue that include all environment

Use this start - https://terragrunt.gruntwork.io/docs/getting-started/quick-start/





terragrunt apply --terragrunt-log-level debug --terragrunt-debug




## v4

create s3 bucket `antonputra-terraform-state`
create IAM role `terraform` with `AdministratorAccess` policy (use least privelaged) mportant for EKS
create IAM policy to asume that role
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Resource": "*"
    }
  ]
}

Create `anton` user
Generate credentials
`cat ~/Downloads/anton_accessKeys.csv`
create profile `aws configure --profile anton`

`vim ~/.aws/config`

```
[profile terraform]
role_arn = arn:aws:iam::424432388155:role/terraform
source_profile = anton
```

aws sts get-caller-identity --profile terraform

Create `AllowTerraformRole`
{
  "Version": "2012-10-17",
  "Statement": {
    "Effect": "Allow",
    "Action": "sts:AssumeRole",
    "Resource": "arn:aws:iam::424432388155:role/terraform"
  }
}

Create IAM group `devops` with `AllowTerraformRole`
Place `anton` to `devops` group

aws sts get-caller-identity --profile terraform

