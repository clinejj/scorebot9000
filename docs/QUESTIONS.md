# Open questions log

Questions that come up while building the PR stack. Each one has the default that was used, so the work never blocks on an answer. Answer at the end; anything that changes a default becomes a follow-up commit.

| # | Raised in | Question | Default used in the meantime |
|---|---|---|---|
| 1 | Plan §16 | Can Scorebot live on your existing PlanetScale Postgres cluster (separate database + roles), or should it get its own database? Which region is it in? | Config assumes a separate `DATABASE_URL`; the Fly region is set to `iad` (us-east) in `fly.toml` |
| 2 | Plan §16 | Is the Fly app name `scorebot9000` available? | `fly.toml` uses `scorebot9000`, `scorebot9000-staging` |
| 3 | PR 2 (foundation) | What operator name and support email should the privacy policy and SMS terms show? Twilio's 10DLC campaign review reads these pages. | Read from `OPERATOR_NAME` / `SUPPORT_EMAIL` env vars; without them the pages say "Scorebot 9000" and "contact the organizer of your event" |
| 4 | PR 3 (sign-in) | Which email provider and From address? The app sends sign-in codes over SMTP. | SMTP settings from `SMTP_ADDRESS`/`SMTP_USERNAME`/`SMTP_PASSWORD`/`SMTP_PORT` (works with Resend or SES); From = `MAIL_FROM`, defaulting to `no-reply@scorebot9000.fly.dev` |
| 5 | PR 3 (sign-in) | Sign-in sessions are per host: signing in on `clinelympics.com` doesn't sign you in on `scorebot9000.fly.dev`. OK for now? | Yes; admin tools are used from the `fly.dev` host |
| 6 | PR 6 (legacy import) | The legacy data never stored event dates. The importer uses each event's first and last score times. Do you want to correct any dates by hand afterwards? | Dates come from score times (or Jan 15 of the year when an event has no scores), editable later in the organizer console |
| 7 | PR 6 (legacy import) | Imported legacy events don't allow alias overrides, and team names are title-cased ("WHEATIES" becomes "Wheaties"). Keep that? | Yes; the official snapshot still shows names as captured |
| 8 | PR 6 (legacy import) | Should players whose legacy ID wasn't a phone number (test entries from the admin simulator) be imported as placeholder users, or dropped? | Imported as placeholder users (no contact info) so their scores still count, and flagged in the report |
| 9 | PR 7 (public site) | On clinelympics.com, event pages live at `/e/clinelympics-2021` (same as on the platform domain) rather than `/2021`. OK? | Yes; old `*.jsp` links redirect permanently |
| 10 | PR 7 (public site) | The series page's all-time medal table credits every game medal to each member of the winning team, shown by each person's most recent alias. Is that the stat you want, or would you rather count overall placements (champion/runner-up) per person? | Game medals per person |
| 11 | PR 7 (public site) | The demo seed data (`bin/rails db:seed`) is for local development only. Should production get any seed data besides the legacy import? | No |
