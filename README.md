# Hybrid_cloud_task_
![terraform](https://www.parkmycloud.com/wp-content/uploads/terraform-x-aws-1.png)
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
```
aws2 configure --profile vishnupal
```

### here i add my  profile in terraform file i already configure in my local system
```
provider "aws" {
  region = "ap-south-1"
  profile = "vishnupal"
}
```
### task 1-> In this task i create new key_pair "terraform_ec2" using resouce tls_private_key. here i use RSA algoritham for creating key new kay pair

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
### task 2-> create a security group Service here ingress is set the inbount rules it mean user can access can we which specfic service so here i open http on port 80 and open ssh on port 22 so here user can access both service 
### here egress is use for ec2 instance which service service can access it mean outside the ec2 instance .
### here add port 443. bcz when i access ssh connection then it is faild it required 443 for connection so i add this port number. and i not use portcol -1 bcz it open all the port . 
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
ingress {

    from_port   = 443
    to_port     = 443
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
egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "Security"
  }
}
```
### I create instance and install httpd , php , git etc on top of ec2 instance  and ip address save in the publicip.txt file
### and here i use "terraform as key_name"  and private key use as generate by my tls_private_key resource or security_group add by create my Security_of_ec2 
```
resource "aws_instance" "web" {
  ami           = "ami-0447a12f28fddb066"
  instance_type = "t2.micro"
  key_name = "terraform_ec2"
  security_groups = ["${aws_security_group.Security_of_ec2.name}"]

  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = tls_private_key.TASK_1.private_key_pem
    host     = aws_instance.web.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install httpd  php git -y",
      "sudo systemctl restart httpd",
      "sudo systemctl enable httpd",

    ]
  }

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
### Here a create a s3-website-vishnupal.com bucket and upload images on my bucket and it is accessible by public. here i download the github images repo  on my local system and using aws2 cli ip copy repo on s3 bucket so it is public so any one can access images
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
### Here i  create cloudfrount domain name for my s3 bucket images data . this domain name use in my main website 

```
data "aws_s3_bucket" "blog_repo" {
  depends_on = [
    aws_s3_bucket_public_access_block.s3_type,
  ]
  bucket = "s3-website-vishnupal.com"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {

    origin_id   = "default"
    domain_name = "${data.aws_s3_bucket.blog_repo.bucket_domain_name}"

    s3_origin_config {
      origin_access_identity = "${aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path}"
    }
  }

  enabled         = true
  is_ipv6_enabled = true
  comment         = "Added authentication to bucket"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "default"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Environment = "development"
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}


output "Domain_name" {
  value = aws_cloudfront_distribution.s3_distribution.domain_name

}
```
```

resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "Some comment"
}



data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${data.aws_s3_bucket.blog_repo.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = ["${aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn}"]
    }
  }
}

```
### i create EBS of 1 GiB and format by ex4 and mount with ec2 instance /var/www/html directory  and  clone the github data in /var/www/html/ directory and for adding my cloudfrount domain i use sed command  bcz /var/www/html directory not provide write permision. my previous logic not work . and here i use index.php file there i add image tag with 
### <img src=http://$a/images/img1.jpg> so here my cloudfrount domain name change with $a . here /images  is my directory store folder name and img1.jpg is image name so my img tag change by this  <img src=http://d25a7yh2otonb9.cloudfront.net/images/img1.jpg> here i add http bcz without http this not recognise this is a link 
```
resource "aws_ebs_volume" "EBS_1" {
  availability_zone = aws_instance.Hybrid_instance.availability_zone
  size              = 1
  tags = {
    Name = "hybrid_ebs"
  }
}

resource "aws_volume_attachment" "ebs_att" {
  device_name  = "/dev/sdh"
  volume_id    = "${aws_ebs_volume.EBS_1.id}"
  instance_id  = "${aws_instance.Hybrid_instance.id}"
  force_detach = true
}

output "myos_ip" {
  value = aws_instance.Hybrid_instance.public_ip
}




resource "null_resource" "nullremote2" {

  depends_on = [
    aws_volume_attachment.ebs_att,
  ]


  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = tls_private_key.TASK_1.private_key_pem
    host        = aws_instance.Hybrid_instance.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkfs.ext4  /dev/xvdh",
      "sudo mount  /dev/xvdh  /var/www/html",
      "sudo rm -rf /var/www/html/*",
      "sudo rm -rf /var/www/html/.git",
      "sudo git clone https://github.com/vishnupal/Hybrid_cloud_task_1.git  /var/www/html/",
      "sudo sed -i 's/$a/${aws_cloudfront_distribution.s3_distribution.domain_name}/g' /var/www/html/index.php",


    ]
  }
}

```

