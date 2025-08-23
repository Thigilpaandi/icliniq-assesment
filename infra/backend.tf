terraform {
  backend "gcs" {
    bucket = "peppy-ridge-469911-c2-tf-state-795949345048"
    prefix = "secure-node-gcr"
  }
}
