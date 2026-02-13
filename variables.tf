variable "project_id" {
  description = "ID del proyecto en GCP"
  type        = string
}

variable "region" {
  description = "Región de GCP"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "Zona de GCP"
  type        = string
  default     = "us-central1-a"
}

variable "image_tag" {
  description = "Tag de imagen del backend"
  type        = string
}

variable "jwt_secret" {
  description = "JWT secret para backend"
  type        = string
  sensitive   = true
}