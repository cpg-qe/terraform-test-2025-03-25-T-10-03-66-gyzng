output "global_ip_address" {
  description = "The global IP address of the load balancer."
  value       = google_compute_global_address.default.address
}

output "backend_instance_name" {
  description = "The name of the backend instance."
  value       = google_compute_instance.default.name
}

output "http_forwarding_rule" {
  description = "The HTTP forwarding rule for the load balancer."
  value       = google_compute_global_forwarding_rule.default.self_link
}
