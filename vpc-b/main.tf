data "terraform_remote_state" "vpc_a" {
  backend = "local"

  config  = {
    path  = "../vpc-a/terraform.tfstate"
  }

}

resource "aws_vpc" "test" {
  cidr_block  = var.vpc_cidr

  tags = {
    Name = local.vpc_name
  }

}

resource "aws_subnet" "test" {
  vpc_id      = aws_vpc.test.id

  cidr_block  = local.subnet_cidr

  tags = {
    Name = local.subnet_name
  }

}

resource "aws_internet_gateway" "test" {
  vpc_id = aws_vpc.test.id

  tags    = {
    Name  = "igw-test"
  }

}

resource "aws_route_table" "test" {
  vpc_id = aws_vpc.test.id

  route {
    cidr_block         = "10.0.0.0/8"
    transit_gateway_id =  data.terraform_remote_state.vpc_a.outputs.tgw_id
  }

  route {
    cidr_block         = "0.0.0.0/0"
    gateway_id         = aws_internet_gateway.test.id
  }

  tags    = {
    Name  = local.rtb_name
  }

}

resource "aws_route_table_association" "test" {
  subnet_id       = aws_subnet.test.id
  route_table_id  = aws_route_table.test.id
}

resource "aws_ec2_transit_gateway_vpc_attachment" "test" {
  vpc_id              = aws_vpc.test.id
  subnet_ids          = [aws_subnet.test.id]
  transit_gateway_id  = data.terraform_remote_state.vpc_a.outputs.tgw_id 

  tags = {
    Name = format("attachment-%s", local.vpc_name)
  }

}