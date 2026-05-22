#!/usr/bin/env bash

set -euo pipefail

CLUSTER_NAME="${CLUSTER_NAME:-policy-gate-test}"
KUBECONFIG_PATH="${KUBECONFIG_PATH:-/tmp/policy-gate-kubeconfig}"
UNSIGNED_IMAGE="${UNSIGNED_IMAGE:-nginx:latest}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

need() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

need docker
need kind
need kubectl

kind get clusters | grep -qx "$CLUSTER_NAME" || kind create cluster --name "$CLUSTER_NAME" --image kindest/node:v1.30.0 --wait 120s
kind get kubeconfig --name "$CLUSTER_NAME" > "$KUBECONFIG_PATH"
export KUBECONFIG="$KUBECONFIG_PATH"

kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/release-3.10/deploy/gatekeeper.yaml
kubectl -n gatekeeper-system patch deployment gatekeeper-controller-manager --type='json' -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--enable-external-data"}]'
kubectl -n gatekeeper-system patch deployment gatekeeper-audit --type='json' -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--enable-external-data"}]'
kubectl -n gatekeeper-system rollout status deployment/gatekeeper-controller-manager --timeout=180s
kubectl -n gatekeeper-system rollout status deployment/gatekeeper-audit --timeout=180s

docker build -t local/cosign-gatekeeper-provider:dev "$ROOT_DIR/policy/cosign-provider"
kind load docker-image local/cosign-gatekeeper-provider:dev --name "$CLUSTER_NAME"

kubectl create namespace cosign-system --dry-run=client -o yaml | kubectl apply -f -
kubectl -n cosign-system create secret generic cosign-public-key \
  --from-file=cosign.pub="$ROOT_DIR/cosign.pub" \
  --dry-run=client -o yaml | kubectl apply -f -

if [[ -n "${GHCR_USERNAME:-}" && -n "${GHCR_PAT:-}" ]]; then
  auth="$(printf '%s:%s' "$GHCR_USERNAME" "$GHCR_PAT" | base64 -w0)"
  dockerconfig="$(mktemp)"
  cat > "$dockerconfig" <<EOF
{"auths":{"ghcr.io":{"auth":"$auth"}}}
EOF
  kubectl -n cosign-system create secret generic ghcr-registry-auth \
    --from-file=config.json="$dockerconfig" \
    --dry-run=client -o yaml | kubectl apply -f -
  rm -f "$dockerconfig"
fi

kubectl apply -f "$ROOT_DIR/policy/gatekeeper/provider-deployment.yaml"
kubectl apply -f "$ROOT_DIR/policy/gatekeeper/provider.yaml"
kubectl apply -f "$ROOT_DIR/policy/gatekeeper/constraint-template.yaml"

for _ in $(seq 1 30); do
  if kubectl get crd k8srequiredimagesignatures.constraints.gatekeeper.sh >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

kubectl apply -f "$ROOT_DIR/policy/gatekeeper/constraint.yaml"
kubectl -n cosign-system rollout status deployment/cosign-gatekeeper-provider --timeout=180s
kubectl create namespace nodegoat-staging --dry-run=client -o yaml | kubectl apply -f -

echo "Running deny test with image: $UNSIGNED_IMAGE"
set +e
kubectl run test-unsigned --image="$UNSIGNED_IMAGE" -n nodegoat-staging
status=$?
set -e

if [[ $status -eq 0 ]]; then
  echo "Expected deny, but deployment was allowed." >&2
  exit 1
fi

echo "Policy gate denied the unsigned image as expected."
