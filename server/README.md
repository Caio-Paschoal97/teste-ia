# Pokemon MMO Server

Backend for the multiplayer Pokemon idle game. Hono + Prisma + Better Auth + Socket.IO.

## Local dev

### Sem Docker: MySQL Workbench + MySQL Server local

O Workbench é o cliente gráfico. O processo que guarda os dados é o **MySQL Server 8.4**. Se já existir uma conexão local funcionando no Workbench, não instale outro servidor.

1. No Workbench, abra uma conexão **Standard TCP/IP** para `127.0.0.1`, porta `3306` (ou a porta configurada). Execute:

   ```sql
   SELECT VERSION(), @@hostname, @@port, @@global.time_zone,
          @@log_bin, @@log_bin_trust_function_creators;
   ```

   Se a conexão for recusada, verifique se o serviço MySQL está iniciado (no Windows, abra **Serviços**) e confira a porta. Se instalou **só** o Workbench, instale também o **MySQL Community Server 8.4 LTS** e inicie o serviço. O Workbench pode ser fechado depois da configuração; o serviço precisa continuar ligado.

2. Para um **ambiente de teste novo**, em uma conexão administrativa local, execute **uma instrução por vez**. Se o banco ou a conta já existirem, pare e confira antes de reutilizá-los. Não apague nada.

   ```sql
   CREATE DATABASE pokeidle CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_bin;
   CREATE USER 'pokeidle'@'127.0.0.1' IDENTIFIED BY RANDOM PASSWORD;
   GRANT ALL PRIVILEGES ON `pokeidle`.* TO 'pokeidle'@'127.0.0.1';
   ```

   Guarde a senha devolvida por `CREATE USER`. A permissão é só para esse banco; não use `root` no backend. A migration cria triggers. **Antes do primeiro deploy**, se `@@log_bin = 1` e `@@log_bin_trust_function_creators = 0`, em um **servidor dedicado apenas a testes** o administrador pode configurar `log_bin_trust_function_creators=1` na seção `[mysqld]` do `my.ini`/`my.cnf` e reiniciar o serviço. Configure também `default-time-zone='+00:00'` se o servidor não estiver em UTC. Em servidor compartilhado, não altere configurações globais: combine o deploy com o DBA.

3. Com Node.js 20+ e npm instalados, **copie** `server/.env.example` para `server/.env` (pode usar o explorador de arquivos; não sobrescreva um `.env` existente). Edite:

   ```dotenv
   DATABASE_URL="mysql://pokeidle:SENHA_CODIFICADA@127.0.0.1:3306/pokeidle"
   ```

   Use a porta verificada no passo 1. Na URL, codifique caracteres especiais da senha (por exemplo, `@` vira `%40`); use a senha original no Workbench. `MYSQL_PASSWORD` é lida apenas pelo Compose e não é necessária aqui. Para esse ambiente novo, gere `BETTER_AUTH_SECRET` com `node -e "console.log(require('node:crypto').randomBytes(32).toString('hex'))"` e coloque o resultado no `.env`. Não compartilhe o arquivo.

4. Na raiz do repositório, execute no terminal (não no editor SQL):

   ```sh
   cd server
   npm ci
   npm run db:generate
   npm run db:deploy
   npm run db:status
   npm run dev
   ```

   Não há seed. O status deve indicar que o banco está atualizado. Confira `http://localhost:8787/healthz`. Em **outro terminal na raiz**, execute `cd game`, `npm ci` e `npm run dev`; abra `http://localhost:5173`. Nas próximas vezes, basta manter o serviço MySQL ligado e iniciar o backend e o jogo. Se houver novas migrations, aplique-as antes de iniciar o backend.

### Alternativa com Docker (opcional)

O Compose substitui apenas o MySQL Server local. Não inicie os dois na mesma porta. Para essa alternativa, prepare `server/.env` conforme `.env.example` (incluindo `MYSQL_PASSWORD`) e, na raiz, execute `docker compose --env-file server/.env up -d --wait mysql`. Continue no passo 4 acima.

## Production (Railway)

1. Create a Railway project with a MySQL 8.4 service
2. Add a service from the `server/` directory
3. Set env vars:
   - `DATABASE_URL` (reference the MySQL service URL, with the mysql:// scheme)
   - `BETTER_AUTH_SECRET` (32-byte random string)
   - `BETTER_AUTH_URL` (your backend URL)
   - `FRONTEND_ORIGIN` (comma-separated allowlist — game URL **and** admin URL,
     e.g. `https://play.example.com,https://admin.example.com`)
   - `ADMIN_BOOTSTRAP_EMAIL` (the email that auto-promotes to admin on first sign-in)
   - `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET` (optional, for Google login)
   - `NODE_ENV=production`
4. Build: `npm ci && npm run db:generate && npm run build`.
5. Start: `npm run db:deploy && npm start` (see `railway.json`). There is no seed step.

**Existing data:** do not just switch the URL. Follow [MYSQL.md](MYSQL.md) for
backup, staged transfer, verification, privileges and rollback.

The game and admin frontends each get built separately (`npm run build` in
`game/` and `admin/`) and deployed to a static host (Vercel, Netlify, Railway
static, etc.). Set `VITE_SERVER_URL` at build time on each so they point at
this server in prod.

## Endpoints

- `POST /api/auth/sign-up/email` — email signup
- `POST /api/auth/sign-in/email` — email login
- `GET  /api/auth/sign-in/social/google` — Google OAuth start
- `POST /api/auth/sign-out`
- `GET  /api/auth/get-session` — current session
- `GET  /api/saves` — get caller's cloud save
- `POST /api/saves` — upload save snapshot
- `GET  /api/profile/me` — caller's profile
- `GET  /api/profile/:username` — public profile
- `GET  /api/friends` — list friends + pending
- `POST /api/friends/request` — `{ username }`
- `POST /api/friends/:id/accept`
- `DELETE /api/friends/:id`
- `GET  /api/chat/:channelId/history` — recent messages

## Socket.IO events

Chat:
- `chat:join` `{ channelId }`
- `chat:leave` `{ channelId }`
- `chat:send` `{ channelId, content }` (ack: `{ ok, id?, error? }`)
- `chat:message` (server → client) `{ id, channelId, content, createdAt, user }`
- `presence:update` (server → client) `{ userId, online }`

Trade:
- `trade:invite` `{ toUserId }` (client → server, ack: `{ ok, tradeId?, expiresAt? }`)
- `trade:invite` (server → client) `{ tradeId, from, expiresAt }`
- `trade:respond` `{ tradeId, accept }` (client → server)
- `trade:start` (server → client) `{ tradeId, other, expiresAt }`
- `trade:offer` `{ tradeId, offer }` (client → server, offer is full Pokemon JSON or null)
- `trade:lock` `{ tradeId, locked }` (client → server)
- `trade:state` (server → client) — broadcast of both sides' offer + lock state
- `trade:cancel` `{ tradeId }` (client → server)
- `trade:complete` (server → client) `{ tradeId, sentMonId, received, otherUser }`
- `trade:cancelled` (server → client) `{ tradeId, reason }`

Auth:
- `session:replaced` (server → client) — fires when another device signs in
  on the same account; client should disconnect + reload.
