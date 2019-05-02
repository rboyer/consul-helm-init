die() {
    echo "ERROR: $1" >&2
    exit 1
}

load_config() {
    if [[ ! -f config.vars.bash ]]; then
        die "missing 'config.vars.bash' config file"
    fi
    source config.vars.bash
    : ${cluster_name=}
    : ${gcloud_project=}
    : ${gcloud_zone=}
    : ${consul_license_file=}

    if [[ -z "${cluster_name}" ]]; then
        die "missing 'cluster_name' config var"
    fi
    if [[ -z "${gcloud_project}" ]]; then
        die "missing 'gcloud_project' config var"
    fi
    if [[ -z "${gcloud_zone}" ]]; then
        die "missing 'gcloud_zone' config var"
    fi
    if [[ -n "${consul_license_file}" ]]; then
        if [[ ! -f "${consul_license_file}" ]]; then
            die "consul license file is not readable at: ${consul_license_file}"
        fi
    fi
}

get_release() {
    if [[ ! -f chart.release.name ]]; then
        echo ""
    else
        cat chart.release.name
    fi
}

get_boot_token() {
    local secret_name
    local token

    secret_name="$(kubectl get secret -o name | grep consul-bootstrap-acl-token)"
    if [[ -z "${secret_name}" ]]; then
        echo ""
    else
        kubectl get "${secret_name}" -o go-template='{{ .data.token | base64decode }}'
    fi
}

wait_for_boot_token() {
    local consul_boot_token

    consul_boot_token="$(get_boot_token)"
    if [[ -z "${consul_boot_token}" ]]; then
        echo "waiting for consul bootstrap token to exist"
        while true; do
            consul_boot_token="$(get_boot_token)"
            if [[ -n "${consul_boot_token}" ]]; then
                break
            fi
            sleep 1
        done
    fi
    echo "${consul_boot_token}"
}

consul_cmd() {
    local release_name
    local pod_name
    local token

    release_name="$(get_release)"
    if [[ -z "${release_name}" ]]; then
        die "no consul to connect to; no chart release"
    fi

    pod_name="${release_name}-consul-server-0"
    kubectl exec "${pod_name}" -it -- consul "$@"
}
