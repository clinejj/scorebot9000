# Open questions log

Questions that come up while building the PR stack. Each one has the default that was used, so the work never blocks on an answer. Answer at the end; anything that changes a default becomes a follow-up commit.

| # | Raised in | Question | Default used in the meantime |
|---|---|---|---|
| 1 | Plan §16 | Can Scorebot live on your existing PlanetScale Postgres cluster (separate database + roles), or should it get its own database? Which region is it in? | Config assumes a separate `DATABASE_URL`; the Fly region is set to `iad` (us-east) in `fly.toml` |
| 2 | Plan §16 | Is the Fly app name `scorebot9000` available? | `fly.toml` uses `scorebot9000`, `scorebot9000-staging` |
| 3 | PR 2 (foundation) | What operator name and support email should the privacy policy and SMS terms show? Twilio's 10DLC campaign review reads these pages. | Read from `OPERATOR_NAME` / `SUPPORT_EMAIL` env vars; without them the pages say "Scorebot 9000" and "contact the organizer of your event" |
| 4 | PR 3 (sign-in) | Which email provider and From address? The app sends sign-in codes over SMTP. | SMTP settings from `SMTP_ADDRESS`/`SMTP_USERNAME`/`SMTP_PASSWORD`/`SMTP_PORT` (works with Resend or SES); From = `MAIL_FROM`, defaulting to `no-reply@scorebot9000.fly.dev` |
| 5 | PR 3 (sign-in) | Sign-in sessions are per host: signing in on `clinelympics.com` doesn't sign you in on `scorebot9000.fly.dev`. OK for now? | Yes; admin tools are used from the `fly.dev` host |
