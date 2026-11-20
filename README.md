# Scorebot 9000

A small event-hosting platform for informal competitions. Players register and submit scores by text message or on the web, and standings update live. It started in 2012 as the scoreboard for the Clinelympic Games.

- **Plan and design:** [`docs/MIGRATION_PLAN.md`](docs/MIGRATION_PLAN.md)
- **Open questions:** [`docs/QUESTIONS.md`](docs/QUESTIONS.md)
- **Legacy app:** [`legacy/`](legacy/) holds the original Java App Engine app, kept for reference until cutover.

## Stack

Rails 8.1 + Hotwire, Tailwind, PostgreSQL (PlanetScale in production), Solid Queue and Solid Cable in the same database, Active Storage on Cloudflare R2. It's deployed to a single auto-suspending Fly.io machine.

## Local development

You need Ruby (see `.ruby-version`) and PostgreSQL 16+ running locally, reachable through the default socket or `DATABASE_URL`.

```bash
bin/setup
```

```bash
bin/dev
```

Run the tests, linter and security scan:

```bash
bin/rails test
```

```bash
bin/rubocop
```

```bash
bin/brakeman --no-pager
```

## IDs

Every app table uses a **UUIDv7** primary key, minted in Ruby before insert (`Uuid7`, `MintsUuidV7`). Models with a public face also get a **prefixed ID** in [TypeID](https://github.com/jetify-com/typeid) format via `has_prefixed_id`:

```ruby
class User < ApplicationRecord
  has_prefixed_id :usr
end

user.public_id                 # => "usr_01h455vb4pex5vsknk084sn02q"
User.find("usr_01h455vb4...")  # model, relation and where(id:) lookups all accept it
PrefixedId.locate("usr_01h…")  # find any record by prefixed ID
```

The prefixed form is a reversible encoding of the stored UUID, so it has no column of its own. Bulk inserts (`insert_all`/`upsert_all`) skip callbacks, so pass `id: Uuid7.generate` there.

## Configuration

All secrets come from environment variables (Fly secrets in production). The repo has no encrypted credentials file or master key.

| Variable | Required in production | Purpose |
|---|---|---|
| `DATABASE_URL` | yes | PlanetScale Postgres connection URL |
| `DATABASE_PREPARED_STATEMENTS` | no | Set `false` when using PlanetScale's pooled (PgBouncer) endpoint |
| `SECRET_KEY_BASE` | yes | `bin/rails secret` |
| `ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY` | yes | `bin/rails db:encryption:init` prints all three |
| `ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY` | yes | |
| `ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT` | yes | |
| `R2_ENDPOINT`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, `R2_BUCKET` | yes | Active Storage on Cloudflare R2 |
| `APP_HOST` | set in `fly.toml` | Host used in emailed links |
| `OPERATOR_NAME`, `SUPPORT_EMAIL`, `SMS_DISPLAY_NUMBER` | recommended | Shown on `/privacy` and `/sms-terms` (needed for 10DLC registration) |

Production refuses to boot when a required variable is missing (`config/initializers/require_production_secrets.rb`).

## Deploying to Fly.io

One-time setup:

```bash
fly apps create scorebot9000
```

```bash
fly secrets set -a scorebot9000 DATABASE_URL=... SECRET_KEY_BASE=... ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY=... ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY=... ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT=... R2_ENDPOINT=... R2_ACCESS_KEY_ID=... R2_SECRET_ACCESS_KEY=... R2_BUCKET=...
```

```bash
fly deploy
```

Migrations run once per deploy through `release_command`. Pushes to `main` deploy automatically after CI passes, once the `FLY_API_TOKEN` repository secret is set (`fly tokens create deploy -a scorebot9000`). Staging uses `fly.staging.toml` (`fly deploy -c fly.staging.toml`).

**Event days:** keep a machine warm with `min_machines_running = 1` (or `fly machine update --autostop=off`), and switch it back afterward. See the plan, section 12.5.
