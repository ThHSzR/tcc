#!/usr/bin/env bash
set -euo pipefail

lab_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
if [[ "${1:-}" == up ]]; then
  "$lab_dir/bootstrap.sh"
fi
if [[ ! -d "$lab_dir/zabbix-docker" ]]; then
  echo 'Execute ./bootstrap.sh primeiro.' >&2
  exit 1
fi

cd "$lab_dir/zabbix-docker"
exec docker --context default compose -f compose_pgsql.yaml -f ../compose.local.yaml "$@"
