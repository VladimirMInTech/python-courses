#!/bin/bash
SEARCH_ENVIRONMENT="$1"

namespaces=$(kubectl get ns -o jsonpath='{.items[*].metadata.name}')

for ns in $namespaces; do
  if [[ "$ns" == d8-* ]]; then
    continue
  fi
  echo "Неймспейс: $ns"
  deployments=$(kubectl get deployments -n "$ns" -o jsonpath='{.items[*].metadata.name}')

  for deployment in $deployments; do
    envs=$(kubectl get deployment "$deployment" -n "$ns" -o jsonpath='{.spec.template.spec.containers[*].env[*].value}' 2>/dev/null)
    if echo "$envs" | grep -q "$SEARCH_ENVIRONMENT"; then
      echo "  Deployment '$deployment' в неймспейсе '$ns' содержит '$SEARCH_ENVIRONMENT'"
    else
      echo "Deployment '$deployment'  ---  "
    fi
  done

  echo
done