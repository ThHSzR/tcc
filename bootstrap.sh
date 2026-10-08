#!/usr/bin/env bash
set -euo pipefail

lab_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
upstream_dir="$lab_dir/zabbix-docker"
secrets_dir="$lab_dir/secrets"
expected_commit=a50de37ac3fbe97b5245a1974627c1a17c6da535

for tool in git openssl docker; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "Dependência ausente: $tool" >&2
    exit 1
  fi
done

if ! docker --context default compose version >/dev/null; then
  echo 'Docker Compose não está disponível no contexto default.' >&2
  exit 1
fi

if [[ ! -d "$upstream_dir/.git" ]]; then
  if [[ -e "$upstream_dir" ]]; then
    echo "O caminho $upstream_dir já existe e não é um clone Git." >&2
    exit 1
  fi
  git clone --branch 7.4 --single-branch https://github.com/zabbix/zabbix-docker.git "$upstream_dir"
  git -C "$upstream_dir" switch --detach "$expected_commit"
fi

actual_commit=$(git -C "$upstream_dir" rev-parse HEAD)
if [[ "$actual_commit" != "$expected_commit" ]]; then
  echo "Clone do Zabbix em revisão diferente: $actual_commit" >&2
  echo "Esperada: $expected_commit. Confira antes de atualizar." >&2
  exit 1
fi

install -d -m 700 "$secrets_dir"
if [[ ! -s "$secrets_dir/postgres-password" ]]; then
  openssl rand -out "$secrets_dir/postgres-password" -base64 36
fi
# Os contêineres leem este arquivo como usuários não-root. A pasta 700
# impede que outros usuários do host acessem o arquivo por este caminho.
chmod 644 "$secrets_dir/postgres-password"

cd "$upstream_dir"
docker --context default compose -f compose_pgsql.yaml -f ../compose.local.yaml config -q
echo 'Laboratório preparado. Execute ./lab.sh up -d na raiz do projeto.'
