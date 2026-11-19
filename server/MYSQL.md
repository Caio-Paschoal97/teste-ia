# MySQL 8.4 — operação e troca do banco

**Destino: um database novo**, InnoDB, `utf8mb4`, servidor em UTC e SQL mode estrito. MySQL 5.7 e MariaDB não são alvos desta baseline. O repositório não contém dados de jogadores nem credenciais reais. `prisma migrate deploy` cria a estrutura; **não transfere dados**.

## Inventário e decisões

| Antes | Agora / cuidado |
|---|---|
| `prisma/schema.prisma`, `migration_lock.toml`, `src/auth.ts`: PostgreSQL, Prisma Client/Migrate 5.22 e adaptador Prisma do Better Auth. `server/.env.example` dizia SQLite (`file:`), incompatível com esse schema. | Um único provider `mysql` local e em produção. O conector MySQL já vem no engine do Prisma: não é preciso adicionar um pool `mysql2`. `src/db.ts` mantém cliente único e usa `ReadCommitted` nas transações (o padrão InnoDB seria `RepeatableRead`). |
| 21 migrations PostgreSQL, incluindo backfills, `DO $$`, CHECKs e a função `error_message_fingerprint`. Dois scripts `scripts/ensure-*.ts` criavam tabelas fora do Migrate. Sem seed registrado nem Compose. | Histórico preservado em `prisma/postgresql-history/`, **fora** da pasta ativa. `prisma/migrations/0_mysql` cria as 34 tabelas finais, índices, unicidade composta, FKs/cascatas e restrições. Triggers de INSERT e UPDATE impedem autoconfronto no ledger: MySQL não permite esse CHECK em colunas com FK em cascata. Os `ensure-*` agora verificam as tabelas sem emitir DDL e orientam a aplicar as migrations se necessário. Não executar backfills antigos sobre o destino; copiar seus resultados da origem. |
| IDs gerados pela aplicação/Prisma (`cuid`, IDs do auth etc.), `TEXT` sem limite, timestamps sem fuso; não havia sequência SERIAL nem dependência de RETURNING. | IDs continuam strings, sem autoincremento. Chaves indexáveis `VARCHAR` (em geral 191 caracteres; email 320, accountId/identifier/channelId 512); `LONGTEXT` para saves, tokens OAuth, conteúdo, snapshots e JSON serializado. Nada é parseado durante a cópia. `DATETIME(3)` em UTC, `DATE` nos dias do ladder, `BOOLEAN` pelo Prisma, `DOUBLE` para coordenadas. Verificar `max_allowed_packet` para o maior save/lote. |
| `src/lib/{audit,errorReporting,presence}.ts`, `src/routes/bugReports.ts`: identificadores entre aspas, `NOW`, `ON CONFLICT`. | SQL parametrizado MySQL, UTC com milissegundos; presença idempotente pela chave `(userId,day)`. |
| `src/routes/admin.ts`, `scripts/errors.ts`: `mode: insensitive`, `ANY`, `$1`, `::bigint/text`, `ILIKE`, `array_agg`, função PostgreSQL e janelas. | Busca textual administrativa com `LOWER/LIKE` somente onde necessário; `utf8mb4_0900_bin` (case-sensitive e sem padding) para não colapsar nomes, IDs e tokens. Usar capitalização **exata** de tabelas (Linux). Paginação parametrizada, contagens convertidas em números, janelas MySQL 8 e expressão ICU compartilhada em `lib/errorFingerprint.ts`. Testar buscas e agrupamentos com Unicode da base real: regras de caixa/regex não são idênticas entre motores. |
| `src/lib/pvpLadder.ts`, `src/routes/pvp.ts`: casts, agregações `FILTER`, upserts condicionais, contagem de linhas para arbitrar prêmios. | `CASE` nos agregados, data UTC, unicidade no ledger e no marco; apenas erro de chave duplicada é tratado como replay. Bônus arbitrado sob lock por conta, conferindo o `matchId` vencedor (não depende de `CLIENT_FOUND_ROWS`). Os 6 CHECKs remanescentes incluem o valor positivo do proxy de leilão. |
| Railway: `server/railway.json` já gerava client, compilava e aplicava `migrate deploy` antes do start. CI, Vitest, testes de drift/fakes e READMEs referenciavam o provider antigo. | Mesmo pipeline de deploy, com URL MySQL explícita. Jogo, painel, renderer e ferramentas de assets não abrem conexões SQL; usam a API/Socket.IO ou armazenamento local do navegador. |

## Ambiente

Comandos de primeira instalação no [README](README.md#local-dev). O Compose sobe **só o banco**, com volume persistente e porta 3306 limitada ao loopback. `docker compose --env-file server/.env stop` preserva o volume. Não use `down -v`. As senhas de inicialização da imagem só são aplicadas na primeira criação do volume.

- `server/.env`: `DATABASE_URL=mysql://usuario:senha@host:3306/database` (percent-encode nos componentes da URL), `MYSQL_PASSWORD` no Compose local (senha literal correspondente). Na Railway, referenciar a URL **interna do serviço MySQL** na variável `DATABASE_URL` do backend; não usar o usuário/senha de exemplo. Configurar TLS de acordo com o provedor.
- `BETTER_AUTH_SECRET` (32 bytes aleatórios; **preservar o segredo existente** na troca), `BETTER_AUTH_URL`, `FRONTEND_ORIGIN` (jogo e admin separados por vírgula), `PORT`, `ADMIN_BOOTSTRAP_EMAIL` e demais opcionais continuam em `server/.env.example`. Não publicar `.env`.
- Em `server/`: `npm run db:generate`, `npm run db:deploy`, `npm run db:status`; depois `npm run dev` ou `npm run build && npm start`. Não há seed. `npm run db:migrate` é **somente para autoria em desenvolvimento**, com usuário que possa criar/remover um *shadow database* descartável. O usuário local do Compose é limitado ao database da aplicação; `db:deploy` não requer shadow. Nunca use `db push`, `migrate reset` ou `migrate resolve` para fazer a troca.
- Ao gerar migrations futuras, revise o SQL **antes** de aplicá-lo: novas tabelas e colunas que participam de FKs devem usar a mesma collation `utf8mb4_0900_bin` da baseline. A collation e os triggers não são representáveis no schema Prisma.
- A conta de deploy precisa de DDL, `REFERENCES`, `TRIGGER` e acesso ao histórico do Migrate. Com binlog ligado, a instalação de triggers pode exigir `log_bin_trust_function_creators=1` ou ação do DBA. Confirme antes do deploy; não remova os triggers para contornar permissões. A conta de runtime só precisa de DML se o deploy for executado separadamente. DDL MySQL faz commits implícitos: se o primeiro deploy falhar, diagnostique e ensaie em **outro database vazio**, não marque a migration como aplicada à força.

## Dados existentes: ensaio e cutover offline

1. **Antes de parar produção**, faça backup consistente (por exemplo `pg_dump -Fc` com `PGSERVICE` configurado), teste o restore em ambiente isolado e retenha versão do servidor, variáveis e histórico PostgreSQL. O copiador espera tabelas Prisma finais no schema `public`; se faltarem migrations, houver drift, um SQLite local real ou tabelas extras, pare para mapear a origem. Não altere produção para fazer o script passar.
2. Prepare um MySQL separado e vazio, aplique `db:deploy` **sem iniciar o backend**. Primeiro ensaie sobre o restore. Dimensione espaço para dados, índices e undo log: a cópia inteira usa uma transação InnoDB e relê as tabelas; para bases grandes ou troca sem downtime, planeje ETL/replicação com DBA em vez deste procedimento offline.
3. Em `server/`, configure fora do Git um ambiente Python 3.10+ para a ferramenta **opcional** (não participa do runtime Node):

   ```bash
   python3 -m venv .venv
   .venv/bin/pip install -r scripts/copy-requirements.txt
   # Exporte via gerenciador de segredos SOURCE_DATABASE_URL (postgresql://...,
   # usuário só de leitura, com SSL verificado) e DATABASE_URL (mysql://... do destino).
   # O copiador não lê .env e não aceita query string MySQL: use MYSQL_CA_FILE
   # para TLS verificado em destino remoto ou túnel SSH em loopback.
   .venv/bin/python scripts/copy-postgres.py          # preflight de estrutura/destino vazio
   .venv/bin/python scripts/copy-postgres.py --apply  # somente no destino OFFLINE
   ```

   Copia por nome de coluna e ordem de dependência, sem DDL, `IGNORE`, upsert ou desativação de FKs. Mantém IDs, versão dos saves, sessões, hashes, grants, cooldowns e baselines de rating. Exclui **apenas** `_prisma_migrations` (histórico específico do motor). Compara todas as colunas linha a linha com o snapshot PostgreSQL antes do commit. Diferença de comprimento, FK, CHECK ou conteúdo: abortar e investigar; **não truncar nem deduplicar**. Proteja os backups e os logs da ferramenta como material sensível.
4. **Corte real:** coloque o jogo em manutenção e drene **todos** os escritores (incluindo sockets, timers, serviços e CLIs) antes do snapshot final. Repita a cópia para outro MySQL novo, sem escritores concorrentes, e reconcilie contagens e amostras. Valide login com sessão existente, upload/download de save e CAS, chat e presença, painel de erros, leilões e uma liquidação PvP em staging. Só então aponte o backend novo para MySQL, confira `/healthz`, logs e fluxos reais e reabra as escritas.
5. **Rollback:** mantenha PostgreSQL e aplicação anterior intactos. Antes de aceitar escritas no destino, é possível voltar URL **e versão do código** juntas. Depois disso, congelar novamente e reconciliar escritas novas antes de voltar; reverter só a URL perderia progresso. Não há sincronização contínua nem rollback de dados automático.

A CI usa um MySQL 8.4 descartável; os testes Vitest usuais continuam isolados e não usam as credenciais do desenvolvedor.
