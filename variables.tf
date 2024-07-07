# Variables
variable "project_name" {
  description = "Project name to be used in resource names"
  type        = string
  default = "api-gym"
}

variable "your_ip" {
  description = "Your IP address to allow SSH access"
  type        = string
  default = "143.137.96.132"
}

