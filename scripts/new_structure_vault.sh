#!/bin/bash

VAULT_ADDR=""
VAULT_TOKEN=""
VAULT_NAMESPACE=""
VAULT_ENGINES_TO_CHANGE_STRUCTURE=()
VAULT_FOLDER_TO_CHANGE_STRUCTURE=()

function contains() {
  local item match="$1"
  shift
  for item; do
    [[ "$item" == "$match" ]] && return 0
  done
  return 1
}

function get_vault_engines() {
  vault_engines=$(curl -s -w "%{http_code}"  -H "X-Vault-Token: $2" \
                                             -H "X-Vault-Namespace: $3" \
                                             "$1/v1/sys/mounts" )
  vault_engines_http_code="${vault_engines: -3}"
  vault_engines_body="${vault_engines:0:-3}"

  if [ $vault_engines_http_code -ne 200 ]; then
    echo "Failed get vault_engines with http_code: ${vault_engines_http_code}"
    exit 1
  fi

  list_vault_engines=$(echo "$vault_engines_body" | jq -r '.data | keys[]')
  list_system_vault_engines=("cubbyhole/" "identity/" "service_accounts/" "sys/")
  readarray -t vault_engines_array <<< "$list_vault_engines"


  for vault_engine in "${vault_engines_array[@]}"; do
    if ! contains "$vault_engine" "${list_system_vault_engines[@]}"; then
      list_engines_for_get_secrets+=("${vault_engine}")
    fi
    if contains "$vault_engine" "${VAULT_ENGINES_TO_CHANGE_STRUCTURE[@]}"; then
      list_engines_for_changed_structure+=("${vault_engine}")
    fi
  done

  for item in "${list_engines_for_changed_structure[@]}"; do
    echo $item
      get_folder_from_engine "${VAULT_ADDR}" "${VAULT_TOKEN}" "${VAULT_NAMESPACE}" "${item}"
  done

}

function get_folder_from_engine() {
  vault_engine_folder=$(curl -s -w "%{http_code}"  -H "X-Vault-Token: $2" \
                                                   -H "X-Vault-Namespace: $3" \
                                                   -X LIST \
                                                   "$1/v1/$4metadata" )
  vault_engine_folder_http_code="${vault_engine_folder: -3}"
  vault_engine_folder_body="${vault_engine_folder:0:-3}"
  if [ $vault_engine_folder_http_code -ne 200 ]; then
    echo "Failed get folder from engine $4 with http_code: ${vault_engine_folder_http_code}"
    exit 1
  fi
  list_vault_engines_folder=$(echo "$vault_engine_folder_body" | jq -r '.data.keys | values[]')
  readarray -t list_vault_engine_folder <<< "$list_vault_engines_folder"

  declare -A list_folder_for_get_secrets=()

  for item in "${list_vault_engine_folder[@]}"; do
    if contains "${item}" "${VAULT_FOLDER_TO_CHANGE_STRUCTURE[@]}"; then
      list_folder_for_get_secrets["$item"]=1
    fi
  done
  for item in "${!list_folder_for_get_secrets[@]}"; do
      get_secrets_from_folder "${VAULT_ADDR}" "${VAULT_TOKEN}" "${VAULT_NAMESPACE}" "$4" "${item}"
  done
}

function get_secrets_from_folder(){
  vault_folder_secrets=$(curl -s -w "%{http_code}" -H "X-Vault-Token: $2" \
                                                   -H "X-Vault-Namespace: $3" \
                                                   -X LIST \
                                                   "$1/v1/$4metadata/$5" )
  vault_folder_secrets_http_code="${vault_folder_secrets: -3}"
  vault_folder_secrets_body="${vault_folder_secrets:0:-3}"
  if [ $vault_folder_secrets_http_code -ne 200 ]; then
    echo "Failed get secrets from folder $4 with http_code: ${vault_folder_secrets_http_code}"
    exit 1
  fi
  list_secrets_folders=$(echo "$vault_folder_secrets_body" | jq -r '.data.keys | values[]')
  readarray -t list_secret_folder <<< "$list_secrets_folders"

  for item in "${list_secret_folder[@]}"; do
    get_data_latest_secrets_version "${VAULT_ADDR}" "${VAULT_TOKEN}" "${VAULT_NAMESPACE}" "$4" "$5" "${item}"
#    get_data_latest_secrets_version "${VAULT_ADDR}" "${VAULT_TOKEN}" "${VAULT_NAMESPACE}" "test/" "wezen/" "lmdb-repository"
  done
}

function get_data_latest_secrets_version (){
  vault_data_latest_secrets_version=$(curl -s -w "%{http_code}" -H "X-Vault-Token: $2" \
                                                   -H "X-Vault-Namespace: $3" \
                                                   "$1/v1/$4data/$5$6" )
  vault_data_latest_secrets_version_http_code="${vault_data_latest_secrets_version: -3}"
  vault_data_latest_secrets_version_body="${vault_data_latest_secrets_version:0:-3}"
  if [ $vault_data_latest_secrets_version_http_code -ne 200 ]; then
    echo "Failed get data latest version $6 secret from $5 folder  $4 engine  with http_code: ${vault_data_latest_secrets_version_http_code}"
    exit 1
  fi
  data_latest_secrets_version=$(echo "$vault_data_latest_secrets_version_body" | jq -r '.data.data | values[]')
  data_latest_secrets_version_parsed=$(echo -e "$data_latest_secrets_version")
local secrets_array=()
  while IFS= read -r line; do
    if [[ -z "$line" ]]; then
      continue
    fi
    secrets_array+=("$line")
  done <<< "$data_latest_secrets_version"
  json_obj=$(printf '%s\n' "${secrets_array[@]}" | awk -F= '{print "{\"" $1 "\":\"" $2 "\"}"}' | jq -s 'reduce .[] as $item ({}; . * $item)')
  $json=$(jq -n --argjson data "$json_obj" '{data: $data}')
  echo "$json"
  put_secrets_to_folder  "${VAULT_ADDR}" "${VAULT_TOKEN}" "${VAULT_NAMESPACE}" "$4" "$6" "${json}"
}

put_secrets_to_folder(){
  prod_vault_folders=("prod")
  secret_name="$5"
  if [[ "$secret_name" == lmdb-* ]]; then
    secret_name="${secret_name#lmdb-}"
  fi
  excluded_secrets=("SA" "api-load-test" "web")
  if contains "${secret_name}" "${excluded_secrets[@]}"; then
    continue
  else
    env="$4"
    engine="${env%/}"
    local paths=()
    local secret_path
    if contains "${engine}" "${prod_vault_folders[@]}"; then
      paths=()
      secret_path="prod/data/lmdb/lmdb/${secret_name}/prod"
      paths+=("${secret_path}")
    else
      paths=()
      secret_path="stage/data/lmdb/lmdb/${secret_name}/${engine}"
      paths+=("${secret_path}")
    fi

    if [[ "${engine}" == "test" ]]; then
      paths=()
      paths+=("stage/data/lmdb/lmdb/${secret_name}/feature")
      paths+=("stage/data/lmdb/lmdb/${secret_name}/test")
    elif [[ "${engine}" == "stage" ]]; then
      paths=()
#      paths+=("stage/data/lmdb/lmdb/${secret_name}/stage")
      paths+=("stage/data/lmdb/lmdb/${secret_name}/preprod")
    else
      paths=()
      paths+=("${secret_path}")
    fi

    for path in "${paths[@]}"; do
      echo "path = " $path
      declare -a kv_pairs="$6"
      for kv in "${kv_pairs[@]}"; do

        key="${kv%%=*}"
        value="${kv#*=}"
        json_obj=$(echo "$json_obj" | jq --arg k "$key" --arg v "$value" '. + {($k): $v}')
      done
      local body=$(jq -n --argjson data "${json_obj}" '{data: $data}')
      echo "Json for $4 $5 " $body
      vault_put_secrets_to_folder=$(curl -s -w "%{http_code}" \
                                                        -X POST  -H "X-Vault-Token: $2" \
                                                        -H "X-Vault-Namespace: $3" \
                                                        -H "Content-Type: application/json" \
                                                        --data "$body" \
                                                        "$1/v1/${path}")

      local http_code="${vault_put_secrets_to_folder: -3}"
      local resp_body="${vault_put_secrets_to_folder:0:-3}"

      if [[ "$http_code" -eq 200 || "$http_code" -eq 204 ]]; then
        echo "Secret successfully written to $full_path"
      else
        echo "Failed to write secret to $full_path, HTTP code: $http_code"
        echo "Response: $resp_body"
        return 1
      fi
    done
  fi

}
get_vault_engines "${VAULT_ADDR}" "${VAULT_TOKEN}" "${VAULT_NAMESPACE}"