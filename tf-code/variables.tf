
variable "environments" {
  description = "List of environments to create variable groups for"
  type        = list(string)
  default     = ["dev", "qa", "prod"]
}

variable "user_to_invite" {
  description = "A user to invite and add to a group"
  type        = string
}

variable "prefix" {
  description = "Prefix for resource names"
  type        = string
}
