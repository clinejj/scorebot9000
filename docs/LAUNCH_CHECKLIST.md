# Launch checklist

These are the steps that happen outside the code: accounts, secrets, DNS, Twilio and the data migration. They follow the plan's milestones (`docs/MIGRATION_PLAN.md` §13–14). Open questions with their current defaults are in `docs/QUESTIONS.md`.

## Phase 0: safeguard the legacy data (do this first)

- [ ] **Export Datastore** (owner access on project `clinelympics`):

  ```bash
  gcloud config set project clinelympics
  ```

  ```bash
  gcloud storage buckets create gs://clinelympics-legacy-export --location=US
  ```

  ```bash
  gcloud datastore export gs://clinelympics-legacy-export/$(date +%F)
  ```

- [ ] **Dump to JSONL** for the importer. The file contains phone numbers, so keep it out of git (`tmp/` is ignored):

  ```bash
  gcloud auth application-default login
  ```

  ```bash
  ruby script/legacy/dump_datastore.rb --project clinelympics --out tmp/legacy/legacy_dump.jsonl
  ```

- [ ] **Capture the announced results** while clinelympics.com is still up, then commit `db/legacy_results/`:

  ```bash
  ruby script/legacy/capture_results.rb
  ```

- [ ] **Twilio A2P 10DLC:** register the Sole Proprietor brand in Trust Hub (plan §9.5).
- [ ] **Twilio geo permissions:** restrict Messaging and Verify to US/Canada.

## Phase 1: infrastructure

- [ ] **PlanetScale Postgres:**
  - a database for production (and one for staging)
  - an app role (read/write) and a **SELECT-only `scorebot_blazer` role**
- [ ] **Cloudflare R2:** a private bucket for Active Storage, plus an API token scoped to it.
- [ ] **Email:** a Resend (or SES) SMTP credential, with a verified sending domain for `MAIL_FROM`.
- [ ] **Twilio:**
  - a Verify Service (`TWILIO_VERIFY_SERVICE_SID`)
  - a Messaging Service containing the 909 number, with its incoming webhook set to `https://scorebot9000.fly.dev/twilio/sms`
  - Advanced Opt-Out on, with the HELP reply listing the commands (or just "Text COMMANDS for the list")
- [ ] **Fly:**

  ```bash
  fly apps create scorebot9000
  ```

  ```bash
  fly secrets set -a scorebot9000 DATABASE_URL=... BLAZER_DATABASE_URL=... SECRET_KEY_BASE=$(bin/rails secret) ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY=... ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY=... ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT=... R2_ENDPOINT=... R2_ACCESS_KEY_ID=... R2_SECRET_ACCESS_KEY=... R2_BUCKET=... SMTP_ADDRESS=... SMTP_USERNAME=... SMTP_PASSWORD=... MAIL_FROM=... TWILIO_ACCOUNT_SID=... TWILIO_AUTH_TOKEN=... TWILIO_VERIFY_SERVICE_SID=... OPERATOR_NAME=... SUPPORT_EMAIL=... SMS_DISPLAY_NUMBER="909-SCORE-11 (909-726-7311)"
  ```

  `bin/rails db:encryption:init` prints the three encryption keys. **Store them somewhere safe:** losing them makes the encrypted emails and phone numbers unreadable.

  ```bash
  fly deploy
  ```

- [ ] **GitHub:** add the `FLY_API_TOKEN` repo secret (`fly tokens create deploy -a scorebot9000`) so `main` deploys after CI.
- [ ] **First admin:**

  ```bash
  fly ssh console -a scorebot9000 -C "bin/rails users:grant_admin EMAIL=you@example.com"
  ```

  Then sign in at `/session/new`. In `/admin/flipper`, enable `hosting` and `sms_scoring` for the `platform_admins` group (or just your user).
- [ ] **10DLC campaign:** submit it now that `/privacy` and `/sms-terms` are live.

## Phase 2–4: import and check

- [ ] `/admin/legacy_imports`: upload `legacy_dump.jsonl`, check the counts, and click **Run import**. Progress shows in `/admin/maintenance_tasks`.
- [ ] Review the report: orphans, invalid phones, duplicates, and announced-vs-recomputed differences.
- [ ] Optional: run `Maintenance::Legacy::ReconcileResultsTask` so raw scores match the announced totals.
- [ ] Fix any guessed event dates in `/manage`.
- [ ] Spot-check `/s/clinelympics` and a few `/e/clinelympics-20XX/results` pages against the captured HTML in `tmp/legacy/html/`.

## Cutover A: archive goes live on the new stack

- [ ] Take a final Datastore export and dump, diff it against the Phase 0 dump, and re-run the import.
- [ ] Set up the custom domain:

  ```bash
  fly certs add clinelympics.com -a scorebot9000
  ```

  ```bash
  fly certs add www.clinelympics.com -a scorebot9000
  ```

- [ ] In Cloudflare:
  - add the `_acme-challenge` CNAMEs Fly prints
  - point the apex and `www` at the Fly app, proxied, with SSL mode **Full (strict)**
  - turn on Bot Fight Mode
- [ ] Check that `https://clinelympics.com/summary.jsp?e=10` redirects to the 2021 results.
- [ ] Stop the legacy app (reversible):

  ```bash
  gcloud app update --serving-status=stopped --project clinelympics
  ```

- [ ] Copy the managed export to R2. After a few weeks, delete `legacy/` (tag `legacy-java-final` first).

## Before the next event

- [ ] The 10DLC campaign is approved.
- [ ] Rehearse in `/manage` → SMS simulator, then from a real phone: `REGISTER`, `SCORE`, `UNDO`, `STANDINGS`.
- [ ] On the day, keep a machine warm (`fly scale count 1`, or `fly machine update --autostop=off`). Undo it afterwards.
- [ ] After the closing ceremony: **Finalize** (in the console, or text `ADMIN FINAL`), then `pg_dump` to R2.
