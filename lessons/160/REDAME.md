create `environments`
create `environments/dev`
create `environments/staging`
rename it to `infrastructure-live`
rename it to `infrastructure-live-v1`
create `infrastructure-live-v1/dev/vpc`
create `0-provider.tf`
```
provider "aws" {
  region = "us-east-1"
}

terraform {
  required_version = ">= 1.0"

  backend "local" {
    path = "dev/vpc/terraform.tfstate"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.62"
    }
  }
}
```
create `1-vpc.tf`
```
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "dev-main"
  }
}
```
create `2-igw.tf`
```
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "dev-igw"
  }
}
```
create `3-subnets.tf`
```
resource "aws_subnet" "private_us_east_1a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.0.0/19"
  availability_zone = "us-east-1a"

  tags = {
    "Name"                            = "dev-private-us-east-1a"
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/dev-demo"  = "owned"
  }
}

resource "aws_subnet" "private_us_east_1b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.32.0/19"
  availability_zone = "us-east-1b"

  tags = {
    "Name"                            = "dev-private-us-east-1b"
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/dev-demo"  = "owned"
  }
}

resource "aws_subnet" "public_us_east_1a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.64.0/19"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    "Name"                           = "dev-public-us-east-1a"
    "kubernetes.io/role/elb"         = "1"
    "kubernetes.io/cluster/dev-demo" = "owned"
  }
}

resource "aws_subnet" "public_us_east_1b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.96.0/19"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    "Name"                           = "dev-public-us-east-1b"
    "kubernetes.io/role/elb"         = "1"
    "kubernetes.io/cluster/dev-demo" = "owned"
  }
}
```
create `4-nat.tf`
```
resource "aws_eip" "nat" {
  vpc = true

  tags = {
    Name = "dev-nat"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_us_east_1a.id

  tags = {
    Name = "dev-nat"
  }

  depends_on = [aws_internet_gateway.igw]
}
```
create `5-routes.tf`
```
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "dev-private"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "dev-public"
  }
}

resource "aws_route_table_association" "private_us_east_1a" {
  subnet_id      = aws_subnet.private_us_east_1a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_us_east_1b" {
  subnet_id      = aws_subnet.private_us_east_1b.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "public_us_east_1a" {
  subnet_id      = aws_subnet.public_us_east_1a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_us_east_1b" {
  subnet_id      = aws_subnet.public_us_east_1b.id
  route_table_id = aws_route_table.public.id
}
```
create `6-outputs.tf`
```
output "vpc_id" {
  value = aws_vpc.main.id
}
```
tree .
cd infrastructure-live-v1/dev/vpc
terraform init
terraform apply
open AWS and show VPC & subnets






































































































- start with plain code for vpc and multiple environments
- convert same code to modules
- convert to terragrunt
- run multiple terraform modules at once (vpc - eks)
- use iam role to create EKS and vpc
- go over dependency (mention in intro)
- hooks
- https://github.com/hashicorp/terraform/issues/516
- secrets (https://blog.gruntwork.io/a-comprehensive-guide-to-managing-secrets-in-your-terraform-code-1d586955ace1)
- two types of verioning the terraform mono repo
- add To version modules, you can copy the module folder and append a version number to it. Otherwise, you might need to use some complex repository tagging to achieve versioning.
- Terraform Mono Repo vs. Multi Repo: The Great Debate https://www.hashicorp.com/blog/terraform-mono-repo-vs-multi-repo-the-great-debate

folder structure - https://terragrunt.gruntwork.io/docs/getting-started/configuration/#formatting-hcl-files

A comprehensive guide to managing secrets in your Terraform code
https://blog.gruntwork.io/a-comprehensive-guide-to-managing-secrets-in-your-terraform-code-1d586955ace1

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
create dynamodb table `terraform-lock-table` with `LockID`
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

cd ~/devel/infrastructure-modules
git add .
git commit -m 'create vpc module'
git push origin main
git tag -a "vpc-v0.0.1" -m "First release of vpc module"
git push --follow-tags
open github tags https://github.com/antonputra/infrastructure-modules

create infrastructure-live
cd ~/devel
git clone git@github.com:antonputra/infrastructure-live.git
cd infrastructure-live

add provider session name



the terraform_remote_state data source
https://github.com/gruntwork-io/terragrunt-infrastructure-live-example/issues/8
https://terragrunt.gruntwork.io/docs/reference/config-blocks-and-attributes/#dependency

terragrunt run-all init
terragrunt run-all plan
terragrunt run-all apply