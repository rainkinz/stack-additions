/**
 * The ecr module creates a repository for a docker image using AWS ECR.
 * 
 * Usage:
 *
 *    module "ecr" {
 *      source            = "github.com/rainkinz/stack-additions/ecr"
 *      name              = "mycustomnginx"
 *    }
 *
 */

variable "name" {
  description = "the name of your stack, e.g. \"wb-dev\""
}

resource "aws_ecr_repository" "repo" {
  name = "${var.name}"
}

resource "aws_ecr_repository_policy" "repo" {
  repository = "${aws_ecr_repository.repo.name}"
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
  value = "${aws_ecr_repository.repo.repository_url}"
}
