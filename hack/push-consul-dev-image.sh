#!/bin/bash

set -euo pipefail

make dev-docker

docker tag consul-dev:latest gcr.io/rb-kube-test/consul-dev:v1
docker push gcr.io/rb-kube-test/consul-dev:v1
