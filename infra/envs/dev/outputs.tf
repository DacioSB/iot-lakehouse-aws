output "bucket_names" {
  value = { for layer, m in module.bucket : layer => m.id }
}

output "glue_databases" {
  value = [for db in aws_glue_catalog_database.layer : db.name]
}