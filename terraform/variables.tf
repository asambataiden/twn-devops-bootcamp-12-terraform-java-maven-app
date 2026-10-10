
variable "vpc_cidr_block" {
  default = "10.0.0.0/16"
}
variable "subnet_cidr_block" {
  default = "10.0.10.0/24"
}

variable "availability_zone" {
  default = "eu-north-1a"
}

variable "env_prefix" {
  default = "dev"
}

variable "my_ip" {
  default = "92.75.249.142/32"
}

variable "jenkins_ip" {
  default = "46.101.157.198/32"
}

variable "ssh-key-name" {
  default = "myapp-key-pair"
}

variable "instance_type" {
  default = "t3.micro"
}

variable "user_data_script_location" {
  default = "entry-script.sh"
}

variable "region" {
  default = "eu-north-1"
}
