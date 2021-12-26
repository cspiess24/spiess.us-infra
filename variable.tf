variable "bucket_name" {
    description = "Name of the bucket to hold website files"
}

variable "environment" {
    description = "Name of the environment"
}

variable "minimum_protocol_version" {
  default = "TLSv1.2_2021"
}

variable "cloudflare_zone_id" {
  description = "Zone ID of the Cloudflare DNS zone"
}
