#!/bin/bash

set -euo pipefail

unset CDPATH

cd "$(dirname "$0")"

source functions.bash
load_config

# https://cloud.google.com/kubernetes-engine/docs/quickstart
gcloud config set project "${gcloud_project}"
gcloud config set compute/zone "${gcloud_zone}"

gcloud container clusters create "${cluster_name}"

gcloud container clusters get-credentials "${cluster_name}"

gcloud auth configure-docker

echo "NOTE: make sure you push gcr.io/${gcloud_project}/consul-dev:v1"
echo "NOTE: make sure you push gcr.io/${gcloud_project}/consul-k8s-dev:v1"
