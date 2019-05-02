#!/bin/bash

set -euo pipefail

make dev

cp -f $GOPATH/bin/consul-k8s consul-k8s

cat > Dockerfile-dev <<EOF
FROM hashicorp/consul-k8s:0.7.0
COPY consul-k8s /bin/consul-k8s
EOF

docker build -t consul-k8s-dev:latest -f Dockerfile-dev .

docker tag consul-k8s-dev:latest gcr.io/rb-kube-test/consul-k8s-dev:v1
docker push gcr.io/rb-kube-test/consul-k8s-dev:v1
