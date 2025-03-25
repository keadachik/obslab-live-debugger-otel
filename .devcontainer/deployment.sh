r#!/bin/bash

if [[ -z $DT_OPERATOR_TOKEN || -z $DT_ENDPOINT || -z $DT_API_TOKEN ]] then
    echo "Required variables DT_OPERATOR_TOKEN, DT_ENDPOINT, or DT_API_TOKEN are not set. Exiting..."
    exit 1
fi

kind create cluster --config .devcontainer/kind-cluster.yaml --wait 300s

# ENV var pre-processing
# remove trailing slash on DT_ENDPOINT if it exists
DT_ENDPOINT=$(echo "$DT_ENDPOINT" | sed "s,/$,,")
echo "Removed any trailing slashes in DT_ENDPOINT"

# Need the host name for the debug url link in otel-demo-values.yaml
export DT_HOST=$(echo $DT_ENDPOINT | cut -d'/' -f3 | cut -d'.' -f1)
echo "Setting DT_HOST=$DT_HOST" 

# Base64 encode DT_TOKEN, remove newlines that are auto added
DT_OPERATOR_TOKEN=$(echo -n $DT_OPERATOR_TOKEN | base64 -w 0)

# install the Dynatrace operator
helm install dynatrace-operator oci://public.ecr.aws/dynatrace/dynatrace-operator \
    --create-namespace \
    --namespace dynatrace \
    --atomic

# Apply the Dynakube in ApplicationOnly mode
# using envsubst for env var replacement
envsubst < dynakube.yaml | kubectl apply -f -

# create Otel collector credentials
kubectl create secret generic dynatrace-otelcol-dt-api-credentials \
--from-literal=DT_ENDPOINT=$DT_ENDPOINT/api/v2/otlp \
--from-literal=DT_API_TOKEN=$DT_API_TOKEN

# Install RBAC items so collector can talk to k8s API
# kubectl apply -f collector-rbac.yaml

# Add OpenTelemetry Helm Charts
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
helm repo update

# Install Dynatrace Otel Collector
helm upgrade -i dynatrace-collector open-telemetry/opentelemetry-collector -f collector-values.yaml

# Install the Otel demo app with environment variable substitution for the tenant reference in otel-demo-values.yaml
envsubst < otel-demo-values.yaml | helm upgrade -i my-otel-demo open-telemetry/opentelemetry-demo -f -

# Wait for pods frontend and flagd pods to be ready before we use them
kubectl rollout status deployment frontend-proxy
kubectl rollout status deployment flagd

# Apply configmap with high CPU enabled for the Ad Service
kubectl apply -f flags.yaml

kubectl scale deploy/flagd --replicas=0 && kubectl scale deploy/flagd --replicas=1
