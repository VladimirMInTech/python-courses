#!/bin/bash

SEARCH_ENVIRONMENT="$1"
namespaces=$(kubectl get ns -o jsonpath='{.items[*].metadata.name}')
for ns in $namespaces; do
  if [[ "$ns" == d8-* ]]; then
    continue
  fi
  echo "Неймспейс: $ns"

  configmaps=$(kubectl get configmaps -n "$ns" -o jsonpath='{.items[*].metadata.name}')

  for configmap in $configmaps; do
    data_values=$(kubectl get configmap "$configmap" -n "$ns" -o jsonpath='{.data.*}' 2>/dev/null)
    if echo "$data_values" | grep -q "$SEARCH_ENVIRONMENT"; then
      echo "Конфигмапа '$configmap' в неймспейсе '$ns' содержит '$SEARCH_ENVIRONMENT'"
    else
      echo "Конфигмапа '$configmap'  ------  "
    fi
  done
  echo
done
