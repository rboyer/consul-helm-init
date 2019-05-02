#!/bin/bash

set -euo pipefail

unset CDPATH

cd "$(dirname "$0")"

source functions.bash
load_config

set +e

kubectl delete -f pingpong-pods.yaml || true
kubectl delete -f pingpong-rbac.yaml || true

releases="$(helm list --all -q)"
if [[ -n "${releases}" ]]; then
    for release_name in $releases; do
        echo "nuking release: $release_name"
        helm delete "${release_name}" || true
        helm del --purge "${release_name}" || true
    done
fi
rm -f chart.release.name

# release_name="$(get_release)"
# if [[ -n "${release_name}" ]]; then
#     helm delete "${release_name}" || true
#     helm del --purge "${release_name}" || true
#     rm -f chart.release.name
# fi

pvcs="$(kubectl get pvc -o name)"
if [[ -n "$pvcs" ]]; then
    kubectl delete $pvcs || true
fi

secrets=$(kubectl get secret -o name | grep consul)
if [[ -n "$secrets" ]]; then
    kubectl delete $secrets || true
fi

jobs=$(kubectl get job -o name | grep consul)
if [[ -n "$jobs" ]]; then
    kubectl delete $jobs || true
fi

echo "all clean"
