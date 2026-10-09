# Pro Tour Fantasy Golf (Rails 8)

The marketing and sign-up site for [Pro Tour Fantasy Golf](https://www.protourfantasygolf.com): game formats,
features, pricing, FAQs, a searchable list of leagues, and the Contact Us and New League Request forms.

This is a from-scratch Rails 8 rewrite of the Rails 2.3 app in the sibling `pro-tour-v2.0` repo, which stays live
and untouched until cutover. It is not the game itself; drafting, lineups and standings live in `fantasy-golf` and
`fantasy-golf-rails8`.

There is no database. Pages are static views, the Leagues page reads a flat file, and the two forms send email.

## Setup

Needs the Ruby in `.ruby-version` (install it with rbenv) and Bundler.

```bash
bundle install
bin/rails server    # http://localhost:3002
bin/rails test
```

Port 3002 is Puma's default here, since the other apps on this machine use 3000, 3001 and 3003.

In development and test the forms work end to end without any secrets: they use Google's always-pass reCAPTCHA test
keys, and sent mail is written to `log/development.log` instead of being delivered.

## Deploying

Capistrano deploys from your workstation to Passenger on the new server for the Rails 8 apps:
`bundle exec cap production deploy`. See `config/deploy.rb` and `config/deploy/production.rb`. The server's address
isn't set yet (`w.x.y.z` is a placeholder, to be replaced with the new server's IP; DNS still points at the old
server, so the first deploys go by IP), and it deploys to `/home/admin/protourfantasygolf.com`, the same directory
name legacy uses on its own VPS.

The server needs, once: Ruby 3.4.11 under RVM, a copy of `config/master.key` at
`/home/admin/protourfantasygolf.com/shared/config/master.key` (the deploy stops early if it isn't there), the league
listings file at `/home/admin/league_listings.txt` (or `LEAGUE_LISTINGS_PATH`), and a Passenger site pointing at
`current/public`. The secrets (`recaptcha.secret_key` and `postmark.server_token`) live in the encrypted credentials.
The full checklist is in `CLAUDE.md`, under "Before the first production deploy".

## More

`CLAUDE.md` has the current status, the decisions made so far, how this differs from the legacy app, and the
conventions to follow when adding a page.
