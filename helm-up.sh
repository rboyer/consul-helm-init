#!/bin/bash

set -euo pipefail

unset CDPATH

cd "$(dirname "$0")"

source functions.bash
load_config

release_name="$(get_release)"
if [[ -z "${release_name}" ]]; then
    echo "initialize helm and tiller..."
    kubectl apply -f tiller-rbac.yaml
    helm init --history-max 200 --service-account tiller

    while true; do
        helm version && break
        sleep 1
    done

    kubectl create secret generic c-gossip --from-literal="key=$(consul keygen)"
    if [[ -n "${consul_license_file}" ]]; then
        kubectl create secret generic c-license --from-file="key=${consul_license_file}"
    fi

    cat > helm-consul-values.yaml <<EOF
global:
  image: "gcr.io/${gcloud_project}/consul-dev:v1"
  imageK8S: "gcr.io/${gcloud_project}/consul-k8s-dev:v1"
  bootstrapACLs: true
  gossipEncryption:
    enabled: true
    secretName: c-gossip
    secretKey: key

server:
  enterpriseLicense:
    secretName: ${consul_license_file:+c-license}
    secretKey: ${consul_license_file:+key}

client:
  grpc: true

dns:
  enabled: false

ui:
  enabled: false

syncCatalog:
  enabled: false

connectInject:
  enabled: true
EOF

    if [[ ! -d "consul-helm/.git" ]]; then
        git clone https://github.com/hashicorp/consul-helm.git
    fi

    (
    cd consul-helm
    # git checkout master
    # git fetch origin
    # git reset --hard origin/master

    echo "install consul helm chart"
    helm install -f ../helm-consul-values.yaml ./
    )

    release_name="$(helm list -q)"
    if [[ -z "${release_name}" ]]; then
        die "nothing installed?"
    fi

    echo "${release_name}" > chart.release.name

else
    echo "skipping helm, tiller, and chart"
fi

token="$(wait_for_boot_token)"
echo "bootstrap token is: ${token}"
echo

echo "checking for consul members to ensure token is valid"
consul_cmd members -token="${token}"
echo

echo "auth methods>>>"
consul_cmd acl auth-method list -token="${token}"
echo

echo "binding rules>>>"
consul_cmd acl binding-rule list -token="${token}"
echo

if [[ -n "${consul_license_file}" ]]; then
    echo "license >>>"
    consul_cmd license get -token="${token}"
    echo
fi

echo "============== SETUP PINGPONG =============="
echo

echo "allow ping pong bidirectional connect traffic"
consul_cmd intention check -token="${token}" ping pong || {
    consul_cmd intention create -token="${token}" ping pong
}
consul_cmd intention check -token="${token}" pong ping || {
    consul_cmd intention create -token="${token}" pong ping
}
echo

echo "create service accounts"
kubectl apply -f pingpong-rbac.yaml

kubectl apply -f pingpong-pods.yaml
