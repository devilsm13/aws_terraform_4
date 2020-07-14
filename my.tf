provider "aws" {
  region = "ap-south-1"
  profile = "shhhhubhammmm"
}

#VPC
resource "aws_vpc" "myvpc" {
  cidr_block       = "192.168.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = "true"

  tags = {
    Name = "myvpc"
  }
}

#Public_Subnet
resource "aws_subnet" "mysubnet-1a" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "192.168.0.0/24"
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = "true"
  depends_on = [
    aws_vpc.myvpc,
  ]

  tags = {
    Name = "mysubnet-1a"
  }
}

#Private_Subnet
resource "aws_subnet" "mysubnet-1b" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "192.168.1.0/24"
  availability_zone = "ap-south-1b"
  depends_on = [
    aws_vpc.myvpc,
  ]

  tags = {
    Name = "mysubnet-1b"
  }
}


#Internet_Gateway
resource "aws_internet_gateway" "myigw" {
  vpc_id = aws_vpc.myvpc.id
  depends_on = [
    aws_vpc.myvpc,
  ]

  tags = {
    Name = "myigw"
  }
}

#Route_Table_IGW
resource "aws_route_table" "rt-1a" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myigw.id
  }
  
  depends_on = [
    aws_vpc.myvpc,
  ]

  tags = {
    Name = "rt-1a"
  }
}

#Subnet_Association_IGW
resource "aws_route_table_association" "assoc-1a" {
  subnet_id      = aws_subnet.mysubnet-1a.id
  route_table_id = aws_route_table.rt-1a.id

  depends_on = [
    aws_subnet.mysubnet-1a,
  ]
}

#EIP
resource "aws_eip" "nat" {
  vpc = true 
}

#NAT_Gateway
resource "aws_nat_gateway" "myngw" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.mysubnet-1a.id

  tags = {
    Name = "myngw"
  }
}

#Route_Table_NAT
resource "aws_route_table" "rt-1b" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.myngw.id
  }
  
  depends_on = [
    aws_vpc.myvpc,
  ]

  tags = {
    Name = "rt-1a"
  }
}

#Subnet_Association_NAT
resource "aws_route_table_association" "assoc-1b" {
  subnet_id      = aws_subnet.mysubnet-1b.id
  route_table_id = aws_route_table.rt-1b.id

  depends_on = [
    aws_subnet.mysubnet-1a,
  ]
}

#Wordpress_SG
resource "aws_security_group" "wordpress-sg" {
  name        = "wordpress-sg"
  description = "allows ssh and http"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    description = "for SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "for HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  depends_on = [
    aws_vpc.myvpc,
  ]

  tags = {
    Name = "wordpress-sg"
  }
}

#Bastion_SG

resource "aws_security_group" "bastion-sg" {
  name        = "bastion-sg"
  description = "allows ssh"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    description = "for SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  depends_on = [
    aws_vpc.myvpc,
  ]

  tags = {
    Name = "wordpress-sg"
  }
}



#SQL_SG
resource "aws_security_group" "sql-sg" {
  name        = "sql-sg"
  description = "allows wordpress and bastion SG"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    description = "for wordpress sg"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.wordpress-sg.id]
  }

  ingress {
    description = "for bastion sg"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [aws_security_group.bastion-sg.id]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }  

  depends_on = [
    aws_vpc.myvpc,
    aws_security_group.wordpress-sg,
    aws_security_group.bastion-sg
  ]

  tags = {
    Name = "sql-sg"
  }
}


#Wordpress_Instance

resource "aws_instance" wordpress {
  ami = "ami-08618eac2c9886e7f"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.mysubnet-1a.id
  key_name = "mykey22"
  vpc_security_group_ids = [aws_security_group.wordpress-sg.id]

  depends_on = [
    aws_subnet.mysubnet-1a,
    aws_security_group.wordpress-sg,
  ]

  tags = {
    Name = "wordpress"
  }
}


#SQL_Instance

resource "aws_instance" sql {
  ami = "ami-0c43027817664ae27"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.mysubnet-1b.id
  key_name = "mykey22"
  vpc_security_group_ids = [aws_security_group.sql-sg.id]

  depends_on = [
    aws_subnet.mysubnet-1b,
    aws_security_group.sql-sg,
  ]

  tags = {
    Name = "sql"
  }
}

resource "aws_instance" bastion {
  ami = "ami-052c08d70def0ac62"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.mysubnet-1a.id
  key_name = "mykey22"
  vpc_security_group_ids = [aws_security_group.bastion-sg.id]

  depends_on = [
    aws_subnet.mysubnet-1a,
    aws_security_group.bastion-sg,
  ]
  

  tags = {
    Name = "bastion"
  }
}

output "Ip_of_wordpress" {
  value = aws_instance.wordpress.public_ip
}


output "Ip_of_bastion" {
  value = aws_instance.bastion.public_ip
}

output "Ip_of_sql" {
  value = aws_instance.sql.private_ip
}

