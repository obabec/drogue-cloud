
function wait_for_resource() {
    local resource="$1"
    shift

    echo "Waiting until $resource exists..."

    while ! kubectl get "$resource" -n "$DROGUE_NS" >/dev/null 2>&1; do
        sleep 5
    done
}

# we nudge (delete the deploys) because of: https://github.com/knative/serving/issues/10344
# TODO: when 10344 is fixed, replace the while loop with the 'kubectl wait'
function wait_for_ksvc() {
    local resource="$1"
    if [ -z "$2" ]; then
        local timeout=$(($(date +%s) + 600))
    else
        local timeout=$(($(date +%s) + $2))
    fi
    shift

    while ((${timeout} > $(date +%s))); do
        if ! kubectl -n "$DROGUE_NS" wait --timeout=60s --for=condition=Ready "ksvc/${resource}"; then
            kubectl -n "$DROGUE_NS" delete deploy -l "serving.knative.dev/service=${resource}"
        else
            break
        fi
    done

    if [ ${timeout} \< "$(date +%s)" ]; then
        die "Error: timed out while waiting for ${resource} to become ready."
    fi
}
