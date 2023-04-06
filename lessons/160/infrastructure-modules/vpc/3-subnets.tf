resource "aws_subnet" "private_us_east_1a" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = "10.0.0.0/19"
  availability_zone = "us-east-1a"

  tags = {
    "Name"                                  = "${var.env}-private-us-east-1a"
    "kubernetes.io/role/internal-elb"       = "1"
    "kubernetes.io/cluster/${var.env}-demo" = "owned"
  }
}

resource "aws_subnet" "private_us_east_1b" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = "10.0.32.0/19"
  availability_zone = "us-east-1b"

  tags = {
    "Name"                                  = "${var.env}-private-us-east-1b"
    "kubernetes.io/role/internal-elb"       = "1"
    "kubernetes.io/cluster/${var.env}-demo" = "owned"
  }
}

resource "aws_subnet" "public_us_east_1a" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = "10.0.64.0/19"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    "Name"                                  = "${var.env}-public-us-east-1a"
    "kubernetes.io/role/elb"                = "1"
    "kubernetes.io/cluster/${var.env}-demo" = "owned"
  }
}

resource "aws_subnet" "public_us_east_1b" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = "10.0.96.0/19"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    "Name"                                  = "${var.env}-public-us-east-1b"
    "kubernetes.io/role/elb"                = "1"
    "kubernetes.io/cluster/${var.env}-demo" = "owned"
  }
}
