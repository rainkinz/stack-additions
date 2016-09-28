variable "name" {
  description = "the name of your stack, e.g. \"wb-dev\""
}

variable "region" {
  description = "the AWS region in which resources are created, you must set the availability_zones variable as well if you define this value to something other than the default"
}

variable "environment" {
  description = "the name of your environment, e.g. \"prod-east\""
}

variable "key_name" {
  description = "the name of the ssh key to use, e.g. \"internal-key\""
}

// The access and secret keys will probably go away when I work out 
// how to use aws profiles with terraform
variable "access_key" {
  description = "AWS Access Key"
}

variable "secret_key" {
  description = "AWS Secret key"
}

variable "public_key_path" {
  description = "The path to the public key for the keypair used"
}

provider "aws" {
  region = "${var.region}"
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
}

/**
 * Upload an aws keypair
 */
resource "aws_key_pair" "keypair" {
  key_name = "${var.key_name}"
  public_key = "${file(var.public_key_path)}"
}

resource "aws_ecr_repository" "wbnginx" {
  name = "wbnginx"
}

resource "aws_ecr_repository_policy" "wbnginx" {
  repository = "${aws_ecr_repository.wbnginx.name}"
  policy = <<EOF
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Sid": "new policy",
            "Effect": "Allow",
            "Principal": "*",
            "Action": [
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "ecr:BatchCheckLayerAvailability",
                "ecr:PutImage",
                "ecr:InitiateLayerUpload",
                "ecr:UploadLayerPart",
                "ecr:CompleteLayerUpload",
                "ecr:DescribeRepositories",
                "ecr:GetRepositoryPolicy",
                "ecr:ListImages",
                "ecr:DeleteRepository",
                "ecr:BatchDeleteImage",
                "ecr:SetRepositoryPolicy",
                "ecr:DeleteRepositoryPolicy"
            ]
        }
    ]
}
EOF
}


output "ecr_repository_url" {
  value = "${aws_ecr_repository.wbnginx.repository_url}"
}
