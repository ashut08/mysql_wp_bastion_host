//give provider name to terraform and acces to aws account

provider "aws"{


region= "ap-south-1"
access_key="your acces key"
secret_key="your secret key"


}
//creating our own vpc
resource "aws_vpc" "ashu-vpc" {
  cidr_block       = "192.163.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "ashu-vpc"
  }
}

//creating public subnet for wordpress
resource "aws_subnet" "wpsubnet" {
  vpc_id     = "${aws_vpc.ashu-vpc.id}"
  cidr_block = "192.163.0.0/24"
  map_public_ip_on_launch="true"
  tags = {
    Name = "wpsubnet"
  }
}

//creating private subnet for mysql

resource "aws_subnet" "sqlsubnet" {
  vpc_id     = "${aws_vpc.ashu-vpc.id}"
  cidr_block = "192.163.1.0/24"
  tags = {
    Name = "sqlubnet"
  }
}
//creating internet gateway
resource "aws_internet_gateway" "wpgw" {
  vpc_id = "${aws_vpc.ashu-vpc.id}"

  tags = {
    Name = "wpgw"
  }
}

//creating route table
resource "aws_route_table" "wproute" {
  vpc_id = "${aws_vpc.ashu-vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.wpgw.id}"
 }


  tags = {
    Name = "wproute"
  }
}



//associating route table with wpsubnet
resource "aws_route_table_association" "sub1" {
  subnet_id      = aws_subnet.wpsubnet.id
  route_table_id = aws_route_table.wproute.id
}
//create secuirty group for wordpress for wpsubnet
resource "aws_security_group" "wpSG" {
  name = "wpSG"
  vpc_id = "${aws_vpc.ashu-vpc.id}"
  ingress {
	description= "allow ssh"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }


  ingress {
 	description="allow http "
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }


 egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags ={
   
    Name= "wpSG"
  }

}
//create secuity group for mysql
resource "aws_security_group" "sqlSG" {
  name = "sqlSG"
  description = "managed   for mysql servers"
  vpc_id = "${aws_vpc.ashu-vpc.id}"
  ingress {
    protocol        = "tcp"
    from_port       = 3306
    to_port         = 3306
    security_groups = ["${aws_security_group.wpSG.id}"]
  }


 egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags ={
    
    Name= "sqlSG"
  }

}
# Creating security Group for MySQL to allow bastion host


resource "aws_security_group" "bastion-allow" {
	name        	= "bastion-to-mysql"
	description 	= "ssh from bastion"
	vpc_id      	= aws_vpc.ashu-vpc.id


	ingress {
		description 	= "ssh"
		security_groups =[ aws_security_group.admin-bastion.id , ]
		from_port   	= 22
		to_port     	= 22
		protocol    	= "tcp"
		cidr_blocks 	= ["0.0.0.0/0"]
	}


	egress {
		from_port   	= 0
		to_port     	= 0
		protocol    	= "-1"
		cidr_blocks 	= ["0.0.0.0/0"]
	}


	tags = {
		Name = "bastion-allow"
	}
}
resource "aws_security_group" "admin-bastion" {
	name        	= "bastion-host"
	description 	= "ssh login into bastion host"
	vpc_id      	= "${aws_vpc.ashu-vpc.id}"


	ingress {
		description 	= "ssh"
		from_port   	= 22
		to_port     	= 22
		protocol    	= "tcp"
		cidr_blocks 	= ["0.0.0.0/0"]
	}


	egress {
		from_port   	= 0
		to_port     	= 0
		protocol    	= "-1"
		cidr_blocks 	= ["0.0.0.0/0"]
	}


	tags = {
		Name = "admin-bastion"
	}
}


//create wordpress instances
resource "aws_instance" "wordpress_OS" {
  ami           = "ami-000cbce3e1b899ebd"
  instance_type = "t2.micro"


  subnet_id = "${aws_subnet.wpsubnet.id}"
  vpc_security_group_ids = ["${aws_security_group.wpSG.id}"]
  key_name = "mykey11"
 tags ={
    
    Name= "wordpress_OS"
  }

}
//create mysql instances
resource "aws_instance" "mysql_OS" {
  ami           = "ami-0019ac6129392a0f2"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.sqlsubnet.id}"

  vpc_security_group_ids = ["${aws_security_group.sqlSG.id}"]
  key_name = "mykey11"
 tags ={
   
    Name= "mysql_OS"
  }
}
resource "aws_instance" "bastion-host" {
	ami 				= "ami-0732b62d310b80e97"
	instance_type 		= "t2.micro"
	key_name 			= "mykey11"
     
	subnet_id 			= aws_subnet.wpsubnet.id
	security_groups 	= [ aws_security_group.admin-bastion.id , ]


	tags = {
		Name = "bastion-host"
    }
}

