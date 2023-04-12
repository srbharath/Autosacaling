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
show state file from visual studio code

copy vpc -> staging
delete state `dev`
rename `dev` -> `staging
search for dev in staging folder
tree .
cd infrastructure-live-v1/staging/vpc/
terraform init
terraform apply
open in AWS
terraform destroy
cd ../..
cd dev/vpc/
check AWS console that it was deleted

## Refactor to Terraform modules | convert terraform code to module

create `infrastructure-modules`
copy `vpc` folder to `infrastructure-modules`
delete `dev` and `lock`
rename `0-provider.tf` -> `0-versions.tf`
remove provider
remove backend block
create `7-variables.tf`
```
variable "env" {
  description = "Environment name."
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR (Classless Inter-Domain Routing)."
  type        = string
  default     = "10.0.0.0/16"
}
```

update `vpc_cidr_block`
update `1-vpc.tf` to include variable
```
Name = "${var.env}-main"
```
replace vpc resource variable to `this`

`2-igw.tf`
replace to `this`
replace Name tag

`3-subnets.tf`
remove content
add variables
```
variable "azs" {
  description = "Availability zones for subnets."
  type        = list(string)
}

variable "private_subnets" {
  description = "CIDR ranges for private subnets."
  type        = list(string)
}

variable "public_subnets" {
  description = "CIDR ranges for public subnets."
  type        = list(string)
}

variable "private_subnet_tags" {
  description = "Private subnet tags."
  type        = map(any)
}

variable "public_subnet_tags" {
  description = "Private subnet tags."
  type        = map(any)
}
```
`3-subnets.tf`
```
resource "aws_subnet" "private" {
  count = length(var.private_subnets)

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnets[count.index]
  availability_zone = var.azs[count.index]

  tags = merge(
    { Name = "${var.env}-private-${var.azs[count.index]}" },
    var.private_subnet_tags
  )
}

resource "aws_subnet" "public" {
  count = length(var.public_subnets)

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.public_subnets[count.index]
  availability_zone = var.azs[count.index]

  tags = merge(
    { Name = "${var.env}-public-${var.azs[count.index]}" },
    var.public_subnet_tags
  )
}
```

`4-nat.tf`
update `this`
Name tags

`5-routes.tf`


update `6-outputs.tf`

```
output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}
```

create `infrastructure-live-v2`
create `dev`
create `staging`
create `dev/vpc`
create `main.tf`
```
provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "local" {
    path = "dev/vpc/terraform.tfstate"
  }
}

module "vpc" {
  source = "../../../infrastructure-modules/vpc"

  env             = "dev"
  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.0.0/19", "10.0.32.0/19"]
  public_subnets  = ["10.0.64.0/19", "10.0.96.0/19"]

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
    "kubernetes.io/cluster/dev-demo"  = "owned"
  }

  public_subnet_tags = {
    "kubernetes.io/role/elb"         = 1
    "kubernetes.io/cluster/dev-demo" = "owned"
  }
}
```
create `outputs.tf`
```
output "vpc_id" {
  value = module.vpc.vpc_id
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}
```

tree . | less
cd dev/vpc
terraform init
terraform apply

copy vpc to staging and replace `dev`
```
provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "local" {
    path = "dev/vpc/terraform.tfstate"
  }
}

module "vpc" {
  source = "../../../infrastructure-modules/vpc"

  env             = "dev"
  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.0.0/19", "10.0.32.0/19"]
  public_subnets  = ["10.0.64.0/19", "10.0.96.0/19"]

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
    "kubernetes.io/cluster/dev-demo"  = "owned"
  }

  public_subnet_tags = {
    "kubernetes.io/role/elb"         = 1
    "kubernetes.io/cluster/dev-demo" = "owned"
  }
}
```

terraform init
terraform apply
check in AWS console that we have similar result
destroy both
check in AWS that all destroyed












## Terragrunt

create `infrastructure-live-v3`
create `infrastructure-live-v3/terragrunt.hcl`
```
remote_state {
  backend = "local"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }

  config = {
    path = "${path_relative_to_include()}/terraform.tfstate"
  }
}

generate "provider" {
  path = "provider.tf"
  if_exists = "overwrite_terragrunt"

  contents = <<EOF
provider "aws" {
    region = "us-east-1"
}
EOF
}
```
create `infrastructure-live-v3/dev`
create `infrastructure-live-v3/staging`
create `infrastructure-live-v3/dev/vpc`
create `infrastructure-live-v3/dev/vpc/terragrunt.hcl`
```
terraform {
  source = "../../../infrastructure-modules/vpc"
}

include "root" {
  path = find_in_parent_folders()
}

inputs = {
  env             = "dev"
  azs             = ["us-east-2a", "us-east-2b"]
  private_subnets = ["10.0.0.0/19", "10.0.32.0/19"]
  public_subnets  = ["10.0.64.0/19", "10.0.96.0/19"]

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
    "kubernetes.io/cluster/dev-demo"  = "owned"
  }

  public_subnet_tags = {
    "kubernetes.io/role/elb"         = 1
    "kubernetes.io/cluster/dev-demo" = "owned"
  }
}
```
show how to install terragrunt
cd infrastructure-live-v3/dev/vpc
terragrunt init
terragrunt apply
open infrastructure-live-v3/dev/vpc/terragrunt.hcl to show state declaration
show state file under `.terragrunt-cache`

create `staging/vpc`
copy `terragrunt.hcl` to `staging/vpc`
replace dev to staging
`cd ../..`
`cd staging/vpc`
terragrunt init
terragrunt apply

show the state file for staging
show VPC in aws console

cd ../..
tree .
terragrunt run-all destroy
check in AWS console that all were destroyred


































































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












## Develop Teraform Code to Create VPC
## Convert VPC Terraform Code into Module
## Use Terragrunt to Create VPC



terragrunt hclfmt






helm repo add autoscaler https://kubernetes.github.io/autoscaler
add hooks

https://github.com/gruntwork-io/terragrunt/issues/1996
https://github.com/gruntwork-io/terragrunt/issues/1822
SOLUTION - https://github.com/gruntwork-io/terragrunt/issues/1822

terragrunt run-all plan --terragrunt-exclude-dir kubernetes-addons
terragrunt run-all apply --terragrunt-exclude-dir kubernetes-addons

https://github.com/gruntwork-io/terragrunt/issues/2225

https://twitter.com/i/spaces/1djGXldPqNyGZ?s=20
