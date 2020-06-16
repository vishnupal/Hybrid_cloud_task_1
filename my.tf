provider "aws" {
  region = "ap-south-1"
  profile = "vishnupal"
}
///////////////////////////////
provider "random" {}
resource "tls_private_key" "TASK_1" {
  
  algorithm = "RSA"
  rsa_bits   = 4096
}

module "key_pair" {

  source = "terraform-aws-modules/key-pair/aws"
  key_name   = "terraform_ec2"
  public_key = tls_private_key.TASK_1.public_key_openssh

}

//////////////////////////////

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
//################### EC2_instance ###########################
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
    Name = "lwos1"
  }

}


////////////////////////////////////

resource "aws_s3_bucket" "s3_bucket" {
  bucket        = "s3-website-vishnupal.com"
  acl           = "public-read"
  force_destroy = true

provisioner "local-exec" {
    command = "rm -rvf ./images"
}
provisioner "local-exec" {
  command = "git clone https://github.com/vishnupal/images.git"
}
provisioner "local-exec" {
    command = "aws2 s3 cp ./images s3://s3-website-vishnupal.com --grants read=uri=http://acs.amazonaws.com/groups/global/AllUsers --recursive"
}

   
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


//################### Cloudfrount #########################################
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




///////////////////////////////





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






////////////////////





resource "aws_ebs_volume" "esb1" {
  availability_zone = aws_instance.web.availability_zone
  size              = 1
  tags = {
    Name = "lwebs"
  }
}


resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = "${aws_ebs_volume.esb1.id}"
  instance_id = "${aws_instance.web.id}"
  force_detach = true
}


output "myos_ip" {
  value = aws_instance.web.public_ip
}





resource "null_resource" "nullremote3"  {

depends_on = [
    aws_volume_attachment.ebs_att,
  ]


  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = tls_private_key.TASK_1.private_key_pem
    host     = aws_instance.web.public_ip
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

