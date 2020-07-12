provider "aws" {
  region  ="ap-south-1"
  profile  ="myvidhi"
}

resource "aws_security_group" "vidhi_sg1"{
  name = "vidhi_sg1"

  ingress {
    description = "SSH"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  } 
  
  egress { 
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "vidhi_sg1"
 }
}

resource "aws_instance" "vidhiins"{
  ami = "ami-0447a12f28fddb066"
  instance_type = "t2.micro"
  key_name = "mykey2"
  security_groups = ["vidhi_sg1"]

 connection {
    type = "ssh"
    user = "ec2-user"
    private_key = file("C:/Users/vidhi/Downloads/mykey2.pem")
    host = aws_instance.vidhiins.public_ip
    }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install httpd git -y",
      "sudo systemctl restart httpd",
      "sudo systemctl enable httpd",
      ]
    }
  
   tags = {
      Name = "Task1_o.s"
    }

    depends_on = [
      aws_security_group.vidhi_sg1,
    ]

}

resource "null_resource" "null1" {
 depends_on = [
    aws_volume_attachment.vidhi_hd1_attach,
  ]
}

resource "aws_ebs_volume" "vidhi_hd1" {
  availability_zone = aws_instance.vidhiins.availability_zone
  size = 1

  tags = {
    Name = "vidhi_hd1"
  }
}

resource "aws_volume_attachment" "vidhi_hd1_attach" {
  device_name = "/dev/sdm"
  volume_id = aws_ebs_volume.vidhi_hd1.id
  instance_id = aws_instance.vidhiins.id
  force_detach = true

  depends_on = [
      aws_ebs_volume.vidhi_hd1,
    ]

  provisioner "remote-exec" {
    inline = [
      "sudo mkfs.ext4 /dev/xvdm",
      "sudo mount /dev/xvdm /var/www/html/*",
      "sudo rm -rf /var/www/html/*",
      "sudo git clone https://github.com/MissAgrawal/Terraform_Aws_Task1.git /var/www/html/"
    ]
  }
  
  connection {
    type = "ssh"
    user = "ec2-user"
    private_key = file("C:/Users/vidhi/Downloads/mykey2.pem")
    host = aws_instance.vidhiins.public_ip
    }
}
resource "aws_s3_bucket" "vidhi_bucket" {
  bucket = "agr-terra-bucket-5454"
  force_destroy = true
  acl = "public-read"

  provisioner "local-exec" {
    command = "git clone https://github.com/MissAgrawal/Terraform_Aws_Task1.git C:/Users/vidhi/Downloads/vimaldaga/software/terra/gitclone"
  }

  provisioner "local-exec" {
    when = destroy
    command = "echo Y | rmdir /S gitclone"
  }
}
  output "out1" {
    value = aws_s3_bucket.vidhi_bucket
  }
resource "aws_s3_bucket_object" "vidhi_object" {
  
  depends_on = [
    aws_s3_bucket.vidhi_bucket,
  ]
 
  bucket = aws_s3_bucket.vidhi_bucket.bucket
  key = "terraform_aws.png"
  source = "C:/Users/vidhi/Downloads/vimaldaga/software/terra/terraform_aws.png"
  acl = "public-read"
  content_type = "image/png"
 
}

resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "my_access_identity"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_s3_bucket.vidhi_bucket.bucket_domain_name
    origin_id   = "agr-terra-bucket-5454"
   
      
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
    }
  }
  enabled = true
  is_ipv6_enabled = true
    
  default_cache_behavior {
    allowed_methods = ["GET", "HEAD"]
    cached_methods = ["GET", "HEAD"]
    target_origin_id = "agr-terra-bucket-5454"
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
    viewer_protocol_policy = "allow-all"
    min_ttl = 0
    default_ttl = 3600
    max_ttl = 86400
  }

restrictions {
      geo_restriction {
        restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

}
      
