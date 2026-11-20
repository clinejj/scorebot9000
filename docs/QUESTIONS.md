# Open questions log

Questions that come up while building the PR stack. Each one has the default that was used, so the work never blocks on an answer. Answer at the end; anything that changes a default becomes a follow-up commit.

| # | Raised in | Question | Default used in the meantime |
|---|---|---|---|
| 1 | Plan §16 | Can Scorebot live on your existing PlanetScale Postgres cluster (separate database + roles), or should it get its own database? Which region is it in? | Config assumes a separate `DATABASE_URL`; the Fly region is set to `iad` (us-east) in `fly.toml` |
| 2 | Plan §16 | Is the Fly app name `scorebot9000` available? | `fly.toml` uses `scorebot9000`, `scorebot9000-staging` |
| 3 | PR 2 (foundation) | What operator name and support email should the privacy policy and SMS terms show? Twilio's 10DLC campaign review reads these pages. | Read from `OPERATOR_NAME` / `SUPPORT_EMAIL` env vars; without them the pages say "Scorebot 9000" and "contact the organizer of your event" |
