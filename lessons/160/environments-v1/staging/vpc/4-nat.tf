resource "aws_eip" "this" {
  vpc = true

  tags = {
    Name = "staging-nat"
  }
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.this.id
  subnet_id     = aws_subnet.public_us_east_1a.id

  tags = {
    Name = "staging-nat"
  }

  depends_on = [aws_internet_gateway.this]
}
