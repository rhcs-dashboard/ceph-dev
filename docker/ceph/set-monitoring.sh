#!/bin/bash

set -e

# Configure grafana
set_grafana_api_url() {
    while true; do
        GRAFANA_IP=$(getent ahosts grafana | tail -1 | awk '{print $1}')
        if [[ -n "$GRAFANA_IP" ]]; then
            "$CEPH_BIN"/ceph dashboard set-grafana-api-url "http://$GRAFANA_IP:$GRAFANA_HOST_PORT"

            return
        fi

        sleep 3
    done
}
set_grafana_api_url &

# Configure alertmanager
set_alertmanager_api_host() {
    while true; do
        ALERTMANAGER_IP=$(getent ahosts alertmanager | tail -1 | awk '{print $1}')
        if [[ -n "$ALERTMANAGER_IP" ]]; then
            "$CEPH_BIN"/ceph dashboard set-alertmanager-api-host "http://$ALERTMANAGER_IP:$ALERTMANAGER_HOST_PORT"

            return
        fi

        sleep 3
    done
}
set_alertmanager_api_host &

# Configure prometheus
set_prometheus_api_host() {
    while true; do
        PROMETHEUS_IP=$(getent ahosts prometheus | tail -1 | awk '{print $1}')
        if [[ -n "$PROMETHEUS_IP" ]]; then
            "$CEPH_BIN"/ceph dashboard set-prometheus-api-host "http://$PROMETHEUS_IP:$PROMETHEUS_HOST_PORT"

            return
        fi

        sleep 3
    done
}
set_prometheus_api_host &
