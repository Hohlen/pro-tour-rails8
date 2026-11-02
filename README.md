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

Capistrano deploys from your workstation to the new cPanel server: `bundle exec cap production deploy`. See
`config/deploy.rb` and `config/deploy/production.rb`. The first deploys go by IP address, since DNS still points at
the old server until the new site is working.

The app deploys to `/home/ptfghost/apps/protourfantasygolf.com`, the path cPanel's Application Manager should have
registered for it (Passenger's app root is `.../current`). Needed once on the server: a copy of `config/master.key`
at `/home/ptfghost/apps/protourfantasygolf.com/shared/config/master.key` (the deploy stops early with a clear message
if it's missing), the league listings file at `/home/ptfghost/apps/protourfantasygolf.com/shared/league_listings.txt` (the deploy stops early, like for the key, if it isn't there), and
Passenger set to run the app with Ruby 3.4.11, which is installed in `/opt/rubies/ruby-3.4.11` (there's no RVM;
Capistrano puts that directory first on the PATH). cPanel's Application Manager lists Rubies by their
`/usr/local/bin/rubyX.Y` name, so the server needs `ln -s /opt/rubies/ruby-3.4.11/bin/ruby /usr/local/bin/ruby3.4`
(already there if another Rails 8 app is set up) and the app's Ruby set to 3.4. The deploy connects as `ptfghost`,
which needs your SSH key in `~/.ssh/authorized_keys`, and GitHub access through your forwarded SSH agent.

The secrets (`recaptcha.secret_key` and `postmark.server_token`) live in the encrypted credentials. `Gemfile.lock`'s
`BUNDLED WITH` must stay equal to the Bundler that ships with Ruby 3.4.11 (2.6.9): a different one makes Bundler
switch versions under Passenger, which fails with "Could not find rails-8.1.4". The full checklist is in `CLAUDE.md`,
under "Before the first production deploy".

## More

`CLAUDE.md` has the current status, the decisions made so far, how this differs from the legacy app, and the
conventions to follow when adding a page.
