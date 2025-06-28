# Use a variable for admin username
variable "admin_username" {
  description = "Username for the VM "
  type        = string
  sensitive   = true
  default     = ""
}





# Use a variable for admin password
variable "admin_password" {
  description = "Password for the VM administrator"
  type        = string
  sensitive   = true
  default     = ""
}
