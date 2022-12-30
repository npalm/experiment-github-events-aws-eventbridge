# variable "prefix" {
#   description = "The prefix used for naming resources"
#   type        = string
#   default     = "friday"
# }

# variable "github_app" {
#   description = "GitHub app parameters, see your github app. Ensure the key is the base64-encoded `.pem` file (the output of `base64 app.private-key.pem`, not the content of `private-key.pem`)."
#   type = object({
#     webhook_secret = string
#   })
# }