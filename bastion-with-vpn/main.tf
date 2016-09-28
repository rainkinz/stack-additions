/**
 * The bastion host acts as the "jump point" for the rest of the infrastructure.
 * Since most of our instances aren't exposed to the external internet, the 
 * bastion acts as the gatekeeper for any direct SSH access and allows clients
 * to connect via vpn.
 * 
 * The bastion is provisioned using the key name that you pass to the stack (and hopefully have stored somewhere).
 * If you ever need to access an instance directly, you can do it by "jumping through" the bastion.
 *
 *    $ terraform output # print the bastion ip
 *    $ ssh -i <path/to/key> ubuntu@<bastion-ip> ssh ubuntu@<internal-ip>
 *
 * Usage:
 *
 *    module "bastion" {
 *      source            = "github.com/rainkinz/stack-additions/bastion-with-vpn"
 *      region            = "us-east-1
 *      security_groups   = "sg-1,sg-2"
 *      vpc_id            = "vpc-12"
 *      key_name          = "ssh-key"
 *      public_subnet_id         = "pub-1"
 *      environment       = "prod"
 *    }
 *
 */

variable "name" {
}

variable "instance_type" {
  default     = "t2.micro"
  description = "Instance type, see a list at: https://aws.amazon.com/ec2/instance-types/"
}

variable "region" {
  description = "AWS Region, e.g us-west-2"
}

variable "security_groups" {
  description = "a comma separated lists of security group IDs"
}

variable "vpc_id" {
  description = "VPC ID"
}

variable "vpc_cidr" {
}

variable "key_name" {
  description = "The SSH key pair, key name"
}

variable "private_key_path" {
  description = "Path to the private key part of the SSH key pair."
}

variable "public_subnet_id" {
  description = "A external subnet id"
}

variable "environment" {
  description = "Environment tag, e.g prod"
}

variable "nat_user" {
  default = "ec2-user"
}


/* module "ami" { */
/*   source        = "github.com/terraform-community-modules/tf_aws_ubuntu_ami/ebs" */
/*   region        = "${var.region}" */
/*   distribution  = "trusty" */
/*   instance_type = "${var.instance_type}" */
/* } */


variable "nat-amis" {
  description = "NAT AMIs to launch the instances with"
  default = {
    us-west-1 = "ami-049d8641"
    us-east-1 = "ami-311a1a5b"
  }
}

/* Security group for the VPN/NAT server */
resource "aws_security_group" "vpn" {
  name        = "${format("%s-%s-external-vpn", var.name, var.environment)}"
  description = "Security group for VPN/NAT instances that allows SSH and VPN traffic from the internet. Allows output HTTP[S]"
  vpc_id = "${var.vpc_id}"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 1194
    to_port = 1194
    protocol = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  // Might need to open and expose these
  /* ingress { */
  /*   from_port = 443 */
  /*   to_port = 443 */
  /*   protocol = "tcp" */
  /*   cidr_blocks = ["0.0.0.0/0"] */
  /* } */

  /* egress { */
  /*   from_port = 443 */
  /*   to_port = 443 */
  /*   protocol = "tcp" */
  /*   cidr_blocks = ["0.0.0.0/0"] */
  /* } */

  lifecycle {
    create_before_destroy = true
  }

  tags {
    Name        = "${format("%s external vpn/ssh", var.name)}"
    Environment = "${var.environment}"
  }
}

resource "aws_instance" "bastion" {
  ami                    = "${lookup(var.nat-amis, var.region)}"
  source_dest_check      = false
  instance_type          = "${var.instance_type}"

  subnet_id              = "${var.public_subnet_id}"
  key_name               = "${var.key_name}"
  vpc_security_group_ids = ["${split(",", var.security_groups)}", "${aws_security_group.vpn.id}"]
  monitoring             = true

  // Example of how we might deploy some userdata
  // user_data              = "${file(format("%s/user_data.sh", path.module))}"
  /* In order to route traffic, they need to have the ’source destination check' parameter disabled */
  source_dest_check = false

  tags {
    Name        = "bastion"
    Environment = "${var.environment}"
  }

  connection {
    // Note the user is EC2 user
    user = "${var.nat_user}"
    key_file = "${var.private_key_path}"
  }

  provisioner "remote-exec" {
    inline = [
      /* Since we're using AWS NAT no need to do this */
      /* "sudo iptables -t nat -A POSTROUTING -j MASQUERADE", */
      /* "echo 1 > /proc/sys/net/ipv4/conf/all/forwarding", */
      /* Install docker */ 
      "curl -sSL https://get.docker.com/ | sudo sh",
      "sudo service docker start",
      /* Initialize open vpn data container */
      "sudo mkdir -p /etc/openvpn",
      "sudo docker run --name ovpn-data -v /etc/openvpn busybox",
      /* Generate OpenVPN server config */
      "sudo docker run --volumes-from ovpn-data --rm gosuri/openvpn ovpn_genconfig -p ${var.vpc_cidr} -u udp://${aws_instance.bastion.public_ip}"
    ]
  }

}

resource "aws_eip" "bastion" {
  instance = "${aws_instance.bastion.id}"
  vpc      = true
}

// Bastion external IP address.
output "external_ip" {
  value = "${aws_eip.bastion.public_ip}"
}

/* // The following are used in the scripts */
/* output "bastion.ip" { */
/*   value = "${aws_instance.bastion.public_ip}" */
/* } */

output "public_dns" {
  value = "${aws_instance.bastion.public_dns}"
}

output "user" {
  value = "${var.nat_user}"
}

output "private_key_path" {
  value = "${var.private_key_path}"
}
