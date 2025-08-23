
variable "project_id"       { type = string }
variable "region"           { type = string }
variable "service_name"     { type = string }
variable "chat_webhook_url" { type = string, default = null }
variable "alert_email"      { type = string, default = null }

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

# Notification channels
resource "google_monitoring_notification_channel" "chat" {
  count        = var.chat_webhook_url == null ? 0 : 1
  display_name = "Dev Chat"
  type         = "google_chat"
  labels = {
    webhook_url = var.chat_webhook_url
  }
}

resource "google_monitoring_notification_channel" "email" {
  count        = var.alert_email == null ? 0 : 1
  display_name = "Ops Email"
  type         = "email"
  labels = {
    email_address = var.alert_email
  }
}

# CPU > 70% -> Chat (warning)
resource "google_monitoring_alert_policy" "cpu_warn" {
  display_name = "Cloud Run CPU > 70% (warn)"
  combiner     = "OR"
  conditions {
    display_name = "CPU utilization > 0.7"
    condition_threshold {
      filter          = "metric.type=\"run.googleapis.com/container/cpu/utilizations\" resource.type=\"cloud_run_revision\" resource.label.service_name=\"${var.service_name}\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.7
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
        cross_series_reducer = "REDUCE_MEAN"
        group_by_fields    = ["resource.label.service_name"]
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
  display_name = "Cloud Run CPU/Memory > 80% (critical)"
  combiner     = "OR"

  conditions {
    display_name = "CPU utilization > 0.8"
    condition_threshold {
      filter          = "metric.type=\"run.googleapis.com/container/cpu/utilizations\" resource.type=\"cloud_run_revision\" resource.label.service_name=\"${var.service_name}\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.8
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
        cross_series_reducer = "REDUCE_MEAN"
        group_by_fields    = ["resource.label.service_name"]
      }
    }
  }

  conditions {
    display_name = "Memory utilization > 0.8"
    condition_threshold {
      filter          = "metric.type=\"run.googleapis.com/container/memory/utilizations\" resource.type=\"cloud_run_revision\" resource.label.service_name=\"${var.service_name}\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.8
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
        cross_series_reducer = "REDUCE_MEAN"
        group_by_fields    = ["resource.label.service_name"]
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
