variable "aws_region" {
  type        = string
  description = "AWS region for all resources"
  default     = "ap-south-1"
}

variable "tag" {
  description = "A map of tags to add additional metadata to the resources."
  type        = map(string)
  default = {
    purpose = "abacus-task-1-test"
  }
}
