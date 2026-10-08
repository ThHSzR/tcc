#!/usr/bin/env bash
set -euo pipefail

lab_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
password_file="$lab_dir/secrets/zabbix-admin-password"
api_url=http://127.0.0.1:8080/api_jsonrpc.php

for tool in curl jq openssl; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "Dependência ausente: $tool" >&2
    exit 1
  fi
done

if [[ -s "$password_file" ]]; then
  IFS= read -r saved_password < "$password_file"
  saved_login=$(jq -cn --arg password "$saved_password" '{jsonrpc:"2.0",method:"user.login",params:{username:"Admin",password:$password},id:1}' | curl -fsS -H 'Content-Type: application/json-rpc' --data-binary @- "$api_url")
  if jq -e '.result | type == "string"' <<< "$saved_login" >/dev/null; then
    echo "Senha do Admin já configurada em $password_file."
    exit 0
  fi
fi

default_login=$(curl -fsS -H 'Content-Type: application/json-rpc' -d '{"jsonrpc":"2.0","method":"user.login","params":{"username":"Admin","password":"zabbix","userData":true},"id":1}' "$api_url")
if ! jq -e '.result.userid and .result.sessionid' <<< "$default_login" >/dev/null; then
  echo 'Não foi possível entrar com a senha padrão. Nenhuma senha foi alterada.' >&2
  exit 1
fi

install -d -m 700 "$lab_dir/secrets"
if [[ ! -s "$password_file" ]]; then
  openssl rand -out "$password_file" -hex 24
fi
chmod 600 "$password_file"
IFS= read -r new_password < "$password_file"
user_id=$(jq -er '.result.userid' <<< "$default_login")
session_id=$(jq -er '.result.sessionid' <<< "$default_login")
update_response=$(jq -cn --arg uid "$user_id" --arg old zabbix --arg new "$new_password" '{jsonrpc:"2.0",method:"user.update",params:{userid:$uid,current_passwd:$old,passwd:$new},id:2}' | curl -fsS -H 'Content-Type: application/json-rpc' -H "Authorization: Bearer $session_id" --data-binary @- "$api_url")
if ! jq -e --arg uid "$user_id" '.result.userids | index($uid) != null' <<< "$update_response" >/dev/null; then
  echo 'A API recusou a mudança da senha do Admin.' >&2
  exit 1
fi

verify_login=$(jq -cn --arg password "$new_password" '{jsonrpc:"2.0",method:"user.login",params:{username:"Admin",password:$password},id:3}' | curl -fsS -H 'Content-Type: application/json-rpc' --data-binary @- "$api_url")
jq -e '.result | type == "string"' <<< "$verify_login" >/dev/null
echo "Senha do Admin alterada e verificada. Consulte $password_file."
