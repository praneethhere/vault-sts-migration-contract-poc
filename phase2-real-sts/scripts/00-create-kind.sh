#!/usr/bin/env bash
set -euo pipefail

kind delete cluster --name sts-cluster-b || true
kind create cluster --config phase2-real-sts/kind/kind-config.yaml
kubectl cluster-info --context kind-sts-cluster-b
