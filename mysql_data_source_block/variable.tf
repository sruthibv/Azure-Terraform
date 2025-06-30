variable "mysql_admin_username" {
  description = "Admin username for MySQL Flexible Server"
  type        = string
}

variable "mysql_admin_password" {
  description = "Admin password for MySQL Flexible Server"
  type        = string
  sensitive   = true
}
