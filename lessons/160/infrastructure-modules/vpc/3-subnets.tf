resource "aws_subnet" "private" {
  count = length(var.private_subnets)

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnets[count.index]
  availability_zone = var.azs[count.index]

  tags = var.private_subnet_tags
}

# tags = merge(
#   {
#     Name = try(
#       var.private_subnet_names[count.index],
#       format("${var.name}-${var.private_subnet_suffix}-%s", element(var.azs, count.index))
#     )
#   },
#   var.tags,
#   var.private_subnet_tags,
#   lookup(var.private_subnet_tags_per_az, element(var.azs, count.index), {})
# )

# resource "aws_subnet" "private_us_east_1a" {
#   vpc_id            = aws_vpc.this.id
#   cidr_block        = "10.0.0.0/19"
#   availability_zone = "us-east-1a"

#   tags = {
#     "Name"                                  = "${var.env}-private-us-east-1a"
#     "kubernetes.io/role/internal-elb"       = "1"
#     "kubernetes.io/cluster/${var.env}-demo" = "owned"
#   }
# }

# resource "aws_subnet" "private_us_east_1b" {
#   vpc_id            = aws_vpc.this.id
#   cidr_block        = "10.0.32.0/19"
#   availability_zone = "us-east-1b"

#   tags = {
#     "Name"                                  = "${var.env}-private-us-east-1b"
#     "kubernetes.io/role/internal-elb"       = "1"
#     "kubernetes.io/cluster/${var.env}-demo" = "owned"
#   }
# }

# resource "aws_subnet" "public_us_east_1a" {
#   vpc_id                  = aws_vpc.this.id
#   cidr_block              = "10.0.64.0/19"
#   availability_zone       = "us-east-1a"
#   map_public_ip_on_launch = true

#   tags = {
#     "Name"                                  = "${var.env}-public-us-east-1a"
#     "kubernetes.io/role/elb"                = "1"
#     "kubernetes.io/cluster/${var.env}-demo" = "owned"
#   }
# }

# resource "aws_subnet" "public_us_east_1b" {
#   vpc_id                  = aws_vpc.this.id
#   cidr_block              = "10.0.96.0/19"
#   availability_zone       = "us-east-1b"
#   map_public_ip_on_launch = true

#   tags = {
#     "Name"                                  = "${var.env}-public-us-east-1b"
#     "kubernetes.io/role/elb"                = "1"
#     "kubernetes.io/cluster/${var.env}-demo" = "owned"
#   }
# }
