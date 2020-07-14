# aws_terraform_4

# AMI of WordPress and MySQL

Here, I have created an Amazon Machine Image (AMI) of WordPress and MySQL.  This setup is typically called LAMP (Linux Apache MySQL PHP).

I have used Amazon Linux AMI for my base instance. I will launch two instances using the same AMI and then, I will install WordPress on the top of 1st one and MySQL on the top of the second one.

One can achieve the entire setup with the help of screenshots in the AMI_screenshots folder. 

# WordPress and MySQL infrastructure on AWS inisde a custom network (VPC). 

The above task has been performed by following the above instructions:

1. Write an Infrastructure as code using terraform, which automatically creates a VPC.

2. In that VPC we have to create 2 subnets:

    1. public subnet [ Accessible for Public World! ] 

    2. private subnet [ Restricted for Public World! ]

3. Create a public facing internet gateway to connect our VPC/Network to the internet world and attach this gateway to our VPC.

4. Create a routing table for Internet gateway so that instance can connect to outside world, update and associate it with public subnet.

5. Create a NAT gateway for connect our VPC/Network to the internet world and attach this gateway to our VPC in the public network

6. Update the routing table of the private subnet, so that to access the internet it uses the nat gateway created in the public subnet

7. Launch an ec2 instance which has Wordpress setup already having the security group allowing port 80 so that our client can connect to our wordpress site. Also attach the key to instance for further login into it.

8. Launch an ec2 instance which has MYSQL setup already with security group allowing port 3306 in private subnet so that our wordpress vm can connect with the same. Also attach the key with the same.



Note: Wordpress instance has to be part of public subnet so that our client can connect our site. 

mysql instance has to be part of private subnet so that outside world can't connect to it.

Don't forget to add auto ip assign and auto DNS name assignment option to be enabled.

# one can get the complete details in the Task4_screenshots folder. 

