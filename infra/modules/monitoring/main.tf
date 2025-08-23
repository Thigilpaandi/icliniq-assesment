
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


resource "google_monitoring_alert_policy" "cpu_warn" {
  display_name = "CPU > 70% (${var.service_name})"
  combiner     = "OR"

  conditions {
    display_name = "CPU utilization > 70%"
    condition_threshold {
      # Cloud Run CPU utilization (GAUGE/DOUBLE)
      filter          = "metric.type=\"run.googleapis.com/container/cpu/utilization\" resource.type=\"cloud_run_revision\" resource.label.\"service_name\"=\"${var.service_name}\""
      comparison      = "COMPARISON_GT"
      threshold_value = 0.70
      duration        = "300s"

      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_MEAN"       # OK for GAUGE/DOUBLE
        cross_series_reducer = "REDUCE_MEAN"
        group_by_fields      = ["resource.label.service_name"]
      }
    }
  }

  notification_channels = concat(
    google_monitoring_notification_channel.chat[*].name
  )
  documentation {
    content = "CPU utilization warning for ${var.service_name}"
  }
}

# CPU or Memory > 80% -> Email (critical)
resource "google_monitoring_alert_policy" "resource_critical" {
  display_name = "Memory > 80% (${var.service_name})"
  combiner     = "OR"

  conditions {
    display_name = "Memory utilization > 80%"
    condition_threshold {
      filter          = "metric.type=\"run.googleapis.com/container/memory/utilization\" resource.type=\"cloud_run_revision\" resource.label.\"service_name\"=\"${var.service_name}\""
      comparison      = "COMPARISON_GT"
      threshold_value = 0.80
      duration        = "300s"

      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_MEAN"
        cross_series_reducer = "REDUCE_MEAN"
        group_by_fields      = ["resource.label.service_name"]
      }
    }
  }


  notification_channels = concat(
    google_monitoring_notification_channel.email[*].name
  )
  documentation {
    content = "Critical resource utilization for ${var.service_name}"
  }
}
