variable "target" {
  description = "Target to trigger"
  type = object({
    name = string
    arn  = string
  })
}

variable "event_bus_name" {
  description = "Event bus name"
  type        = string
}

variable "event_rule" {
  description = "Event rule to trigger the target"
  type = object({
    name = string
    arn  = string
  })
}
