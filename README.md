# TCC — laboratório de monitoramento proativo em redes

V1 executada em Ubuntu com Zabbix 7.4, PostgreSQL e interface Nginx. O projeto usa os [arquivos oficiais de Docker Compose do Zabbix](https://github.com/zabbix/zabbix-docker) na revisão `a50de37ac3fbe97b5245a1974627c1a17c6da535`, baixada por `bootstrap.sh`. A configuração própria do laboratório fica neste repositório.

## Requisitos

- Ubuntu 22.04, 24.04 ou 26.04 de 64 bits; Docker Engine e Docker Compose 2.24.4 ou superior.
- `git`, `openssl` e, para trocar a senha do Admin automaticamente, `curl` e `jq`.
- Para a próxima etapa com MikroTik CHR, virtualização KVM disponível.

## Instalação

```bash
git clone https://github.com/ThHSzR/tcc.git
cd tcc
./lab.sh up -d
./lab.sh ps
```

O primeiro comando `up` baixa o Compose oficial, gera uma senha local para o banco e sobe PostgreSQL, Zabbix Server e Zabbix Web. A inicialização inicial pode levar alguns minutos. O contêiner `server-db-init` terminar com código 0 é esperado.

Quando <http://127.0.0.1:8080/> responder, altere e verifique a senha inicial do usuário `Admin`:

```bash
./secure-admin.sh
```

A senha fica somente em `secrets/zabbix-admin-password`, no seu computador. A senha do banco fica em `secrets/postgres-password`. A pasta `secrets/` e os dados locais são ignorados pelo Git; nunca os publique. Se já houver uma senha Admin válida nesse arquivo, o script apenas a verifica.

## Operação

```bash
./lab.sh ps
./lab.sh logs --tail=100 zabbix-server
./lab.sh stop
./lab.sh up -d
```

Abra <http://127.0.0.1:8080/> e entre como `Admin` com a senha de `secrets/zabbix-admin-password`. A interface e a porta `10051` escutam somente em `127.0.0.1`. O banco não publica porta no host. `lab.sh` usa o Docker Engine no contexto `default`; isso evita o contexto Docker Desktop desativado no notebook em que a V1 foi testada.

Evite `down -v` sem backup: esse comando remove os volumes do banco.

## Próxima etapa: MikroTik CHR

| Segmento | Endereço proposto | Função |
|---|---|---|
| Trânsito Ubuntu ↔ CHR | `192.168.56.0/24` | Rede virtual de gerenciamento |
| Ubuntu/GNS3 | `192.168.56.1` | Ponta de gerenciamento |
| MikroTik CHR | `192.168.56.2` | Roteador virtual |
| LAN simulada | `10.10.10.0/24` | Rede dos serviços e cliente |
| Gateway da LAN | `10.10.10.1` | Interface interna do CHR |
| Servidor Linux | `10.10.10.10` | HTTP/DNS/SSH de teste |
| Cliente Linux | `10.10.10.20` | Tráfego e falhas controladas |

Essas redes ainda não foram criadas. Antes da integração, confirme que não conflitam com a rede atual ou VPN. O Zabbix consultará o CHR por ICMP e SNMP de saída; a configuração SNMP do roteador fica para essa etapa.
