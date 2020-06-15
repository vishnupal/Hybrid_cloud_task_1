# Hybrid_cloud_task_

## PROBLEM STATEMENT :
### Note :- All the task perfome using terraform automation
### 1. Create the key and security group which allow the port 80.
### 2. Launch EC2 instance.
### 3. In this Ec2 instance use the key and security group which we have created in step 1.
### 4. Launch one Volume (EBS) and mount that volume into /var/www/html
### 5. Developer have uploded the code into github repo also the repo has some images.
### 6. Copy the github repo code into /var/www/html
### 7. Create S3 bucket, and copy/deploy the images from github repo into the s3 bucket and change the permission to public readable.
### 8 Create a Cloudfront using s3 bucket(which contains images) and use the Cloudfront URL to  update in code in /var/www/html
## REQUIREMENT 
### 1. AWS account
### 2. Terraform pre installed
### 3. github
### 4. aws2 cli
## EXPLANATION
### Before going to task first of all we create a AMI user using AWS and download athe access key and secret key and do profile configure using aws2 cli
### add provider profile into terraform file
### task 1-> in this task i create new key_pair using 
```
resource "tls_private_key" "TASK_1" {

  algorithm = "RSA"
  rsa_bits  = 4096
}

module "key_pair" {

  source     = "terraform-aws-modules/key-pair/aws"
  key_name   = "terraform_ec2"
  public_key = tls_private_key.TASK_1.public_key_openssh

}
```
```
resource "aws_security_group" "Security_of_ec2" {
  name        = "Service"
  description = "Security_group"


  ingress {

    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {

    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Security"
  }
}
``


```
resource "aws_instance" "Hybrid_instance" {
  ami             = "ami-0447a12f28fddb066"
  instance_type   = "t2.micro"
  key_name        = "terraform_ec2"
  security_groups = ["${aws_security_group.Security_of_ec2.name}"]
  user_data       = <<-EOF
                #! /bin/bash
                sudo su - root
                sudo yum install httpd -y
                sudo yum install php -y
                sudo systemctl start httpd
                sudo systemctl enable httpd
                sudo yum install git -y

                sudo setenforce 0
                EOF
  tags = {
    Name = "Instance_of_vishnupal"
  }
}

resource "null_resource" "nulllocal1" {
  provisioner "local-exec" {
    command = "echo  ${aws_instance.Hybrid_instance.public_ip} > publicip.txt"
  }
}
```
```
resource "aws_s3_bucket" "s3_bucket" {
  bucket        = "s3-website-vishnupal.com"
  acl           = "public-read"
  force_destroy = true

provisioner "local-exec" {
    command = "rm -rvf ./images"
}
//provisioner "local-exec" {
//    command = "git clone https://github.com/vishnupal/images.git"
//}
//provisioner "local-exec" {
//    command = "aws2 s3 cp ./images s3://s3-website-vishnupal.com --grants read=uri=http://acs.amazonaws.com/groups/global/AllUsers --recursive"
//}

   
  tags = {
    Name = "s3_bucket"
  }
}
resource "aws_s3_bucket_public_access_block" "s3_type" {
  bucket              = "${aws_s3_bucket.s3_bucket.id}"
  block_public_acls   = false
  block_public_policy = false
}


output "s3_id" {
  value = aws_s3_bucket.s3_bucket.id
}

```
