
variable "project_id"       { type = string }
variable "region"           { type = string }
variable "service_name"     { type = string }
variable "chat_webhook_url" {
  type    = string
  default = null
}

variable "alert_email" {
  type    = string
  default = null
}

# Log-based metric for errors
resource "google_logging_metric" "app_error_count" {
  name        = "app_error_count"
  description = "Count of error logs from Cloud Run service"
  filter      = "resource.type=\"cloud_run_revision\" AND severity>=ERROR AND resource.labels.service_name=\"${var.service_name}\""
  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
  }
}

# Chat (webhook URL)
resource "google_monitoring_notification_channel" "chat" {
  count        = var.chat_webhook_url == null ? 0 : (length(trimspace(var.chat_webhook_url)) > 0 ? 1 : 0)
  type         = "webhook_tokenauth"
  display_name = "Chat - ${var.service_name}"
  labels = {
    url = var.chat_webhook_url
  }
}

# Email
resource "google_monitoring_notification_channel" "email" {
  count        = var.alert_email == null ? 0 : (length(trimspace(var.alert_email)) > 0 ? 1 : 0)
  type         = "email"
  display_name = "Email - ${var.service_name}"
  labels = {
    email_address = var.alert_email
  }
}


# CPU warn (>70% p95 over 5m)
resource "google_monitoring_alert_policy" "cpu_warn" {
  display_name = "CPU > 70% (${var.service_name})"
  combiner     = "OR"

  conditions {
    display_name = "CPU utilizations p95 > 70%"
    condition_threshold {
      filter          = "resource.type=\"cloud_run_revision\" resource.label.\"service_name\"=\"${var.service_name}\" metric.type=\"run.googleapis.com/container/cpu/utilizations\""
      comparison      = "COMPARISON_GT"
      threshold_value = 0.70          # fraction (70%)
      duration        = "300s"

      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_PERCENTILE_95"
        cross_series_reducer = "REDUCE_MEAN"
        group_by_fields      = ["resource.label.service_name"]
      }
    }
  }

  notification_channels = local.channel_ids
  documentation { content = "CPU p95 > 70% for 5m on ${var.service_name}" }
}

# Memory critical (>80% p95 over 5m)
resource "google_monitoring_alert_policy" "resource_critical" {
  display_name = "Memory > 80% (${var.service_name})"
  combiner     = "OR"

  conditions {
    display_name = "Memory utilizations p95 > 80%"
    condition_threshold {
      filter          = "resource.type=\"cloud_run_revision\" resource.label.\"service_name\"=\"${var.service_name}\" metric.type=\"run.googleapis.com/container/memory/utilizations\""
      comparison      = "COMPARISON_GT"
      threshold_value = 0.80
      duration        = "300s"

      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_PERCENTILE_95"
        cross_series_reducer = "REDUCE_MEAN"
        group_by_fields      = ["resource.label.service_name"]
      }
    }
  }

  notification_channels = local.channel_ids
  documentation { content = "Memory p95 > 80% for 5m on ${var.service_name}" }
}

