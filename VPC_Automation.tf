# create the VPC
resource "aws_vpc" "test_tf_VPC" {
  cidr_block           = var.vpcCIDRblock
  instance_tenancy     = var.instanceTenancy
  enable_dns_support   = var.dnsSupport
  enable_dns_hostnames = var.dnsHostNames
tags = {
    Name = "My tf test VPC"
}
} # end resource
# create the Subnet
resource "aws_subnet" "test_tf_VPC_Subnet" {
  count                   = length(var.subnetCIDRblock)
  vpc_id                  = aws_vpc.test_tf_VPC.id  
  cidr_block              = var.subnetCIDRblock[count.index]
  map_public_ip_on_launch = var.mapPublicIP
  availability_zone       = var.availabilityZone[count.index]
tags = {
   Name = "My tf test VPC Subnet"
}
} # end resource
# Create the Security Group
resource "aws_security_group" "test_tf_VPC_Security_Group" {
  vpc_id       = aws_vpc.test_tf_VPC.id
  name         = "My tf test VPC Security Group"
  description  = "My tf test VPC Security Group"

  # allow ingress of port 22
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
  }

  # allow egress of all ports
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
tags = {
   Name = "My tf test VPC Security Group"
   Description = "My tf test VPC Security Group"
}
}
#Create the static network interface of instance
resource "aws_network_interface" "test_tf_server_interface" {
  count       = length(var.subnetCIDRblock)
  subnet_id   = aws_subnet.test_tf_VPC_Subnet.id
  private_ips = ["172.32.1.100", "172.32.2.100"]
  security_groups = [aws_security_group.test_tf_VPC_Security_Group.id]
  tags = {
    Name = "primary_network_interface"
  }
}
#Create the instance with static network interface
resource "aws_instance" "test_tf_server" {
  ami = "ami-083ebc5a49573896a" # us-east-1a
  instance_type = "t2.micro"
  key_name   = "test_key"
  network_interface {
  network_interface_id = aws_network_interface.test_tf_server_interface.id
  device_index         = 0
  }
  tags = {
    Name = "test_tf_server1"
  }

} # end resource
# create VPC Network access control list
resource "aws_network_acl" "test_tf_VPC_Security_ACL" {
  count  = length(var.subnetCIDRblock)
  vpc_id = aws_vpc.test_tf_VPC.id
  subnet_ids = [ aws_subnet.test_tf_VPC_Subnet.id ]
# allow ingress port 22
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 22
    to_port    = 22
  }

  # allow ingress port 80
  ingress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = var.destinationCIDRblock
    from_port  = 80
    to_port    = 80
  }

  # allow ingress ephemeral ports
  ingress {
    protocol   = "tcp"
    rule_no    = 300
    action     = "allow"
    cidr_block = var.destinationCIDRblock
    from_port  = 1024
    to_port    = 65535
  }
  # allow inress of all ports
  ingress {
    rule_no     = 400
    action      = "allow"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_block  = "0.0.0.0/0"
  }

  # allow egress port 22
  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = var.destinationCIDRblock
    from_port  = 22
    to_port    = 22
  }

  # allow egress port 80
  egress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = var.destinationCIDRblock
    from_port  = 80
    to_port    = 80
  }

  # allow egress port 443
  egress {
    protocol   = "tcp"
    rule_no    = 300
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  # allow egress ephemeral ports
  egress {
    protocol   = "tcp"
    rule_no    = 400
    action     = "allow"
    cidr_block = var.destinationCIDRblock
    from_port  = 1024
    to_port    = 65535
  }

  # allow egress of all ports
  egress {
    rule_no     = 500
    action      = "allow"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_block  = "0.0.0.0/0"
}
tags = {
    Name = "My tf test VPC ACL"
}
} # end resource
# Create the Internet Gateway
resource "aws_internet_gateway" "test_tf_VPC_GW" {
 vpc_id = aws_vpc.test_tf_VPC.id
 tags = {
        Name = "My tf test VPC Internet Gateway"
}
} # end resource
# Create the Route Table
resource "aws_route_table" "test_tf_VPC_route_table" {
 vpc_id = aws_vpc.test_tf_VPC.id
 tags = {
        Name = "My tf test VPC Route Table"
}
} # end resource
# Create the Internet Access
resource "aws_route" "test_tf_VPC_internet_access" {
  route_table_id         = aws_route_table.test_tf_VPC_route_table.id
  destination_cidr_block = var.destinationCIDRblock
  gateway_id             = aws_internet_gateway.test_tf_VPC_GW.id
} # end resource
# Associate the Route Table with the Subnet
resource "aws_route_table_association" "test_tf_VPC_association" {
  count          = length(var.subnetCIDRblock)
  subnet_id      = aws_subnet.test_tf_VPC_Subnet.id
  route_table_id = aws_route_table.test_tf_VPC_route_table.id
} # end resource
# end vpc.tf

# variables.tf
#variable "access_key" {
#    default = "<PUT IN YOUR AWS ACCESS KEY>"
#}
#variable "secret_key" {
#     default = "<PUT IN YOUR AWS SECRET KEY>"
#}
#variable "region" {
#     default = "us-east-1"
#}
variable "availabilityZone" {
     type = list
     default = [ "us-east-2a", "us-east-2b" ]
}
variable "instanceTenancy" {
    default = "default"
}
variable "dnsSupport" {
    default = true
}
variable "dnsHostNames" {
    default = true
}
variable "vpcCIDRblock" {
    default = "172.32.0.0/16"
}
variable "subnetCIDRblock" {
    type = list
    default = [ "172.32.1.0/24", "172.32.2.0/24" ]
}
variable "destinationCIDRblock" {
    default = "0.0.0.0/0"
}
variable "ingressCIDRblock" {
    type = list
    default = [ "0.0.0.0/0" ]
}
variable "egressCIDRblock" {
    type = list
    default = [ "0.0.0.0/0" ]
}
variable "mapPublicIP" {
    default = true
}
# end of variables.tf
