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

Capistrano deploys from your workstation to the new cPanel server: `bundle exec cap production deploy`. The server's
address and user are in `config/deploy/production.rb`; the repository, branch, deploy directory and Ruby path are in
`config/deploy.rb`. Deploys go by IP address on purpose, not by hostname, so a DNS change (a repoint, a Cloudflare proxy) can never send
a deploy to the wrong machine. The deploy connects as `ptfghost`, which needs your SSH key in `~/.ssh/authorized_keys`, and GitHub access
through your forwarded SSH agent.

The app deploys to `/home/ptfghost/apps/protourfantasygolf.com`, and Passenger serves `.../current`. Needed once on
the server:
- A copy of `config/master.key` at `/home/ptfghost/apps/protourfantasygolf.com/shared/config/master.key` (the deploy
  stops early with a clear message if it's missing).
- The league listings file at `/home/ptfghost/apps/protourfantasygolf.com/shared/league_listings.txt`, in the
  8-field format (the deploy stops early, like for the key, if it isn't there).
- Passenger configured for the hostname, as described below.

**Passenger is configured by hand, not through cPanel's Application Manager.** That page (and
`uapi PassengerApps list_applications`) lists nothing for this account, even for the apps that are running. Each app
is an Apache include file, edited as root, in `/etc/apache2/conf.d/userdata/std/2_4/ptfghost/<hostname>/` and in the
matching `ssl/2_4/...` directory (the same file twice, for http and https), named `*-passenger.conf`. For this app,
under `ptfg.hosting.protourfantasygolf.com/`, it sets `PassengerAppRoot` (`.../protourfantasygolf.com/current`),
`PassengerAppEnv "production"`, `PassengerAppGroupName` and **`PassengerRuby /usr/local/bin/ruby3.4`**. Ruby 3.4.11 is
installed in `/opt/rubies/ruby-3.4.11`, and `/usr/local/bin/ruby3.4` is a symlink to it (create it with
`ln -s /opt/rubies/ruby-3.4.11/bin/ruby /usr/local/bin/ruby3.4` if it's missing). There's no RVM: Capistrano puts
`/opt/rubies/ruby-3.4.11/bin` first on the PATH for the deploy. After editing an include file, run
`/scripts/rebuildhttpdconf && httpd -t && /scripts/restartsrv_httpd`.

If the site returns a Passenger 500 ("Web application could not be started") with an Error ID, search for that ID in
Apache's `/var/log/apache2/error_log`; the boot failure is there. "Could not find rails-8.1.4" with
`/usr/share/gems/gems/bundler-...` in the trace means `PassengerRuby` is the system Ruby (`ruby3.3`), not `ruby3.4`.

The secrets (`recaptcha.secret_key` and `postmark.server_token`) live in the encrypted credentials. `Gemfile.lock`'s
`BUNDLED WITH` must stay equal to the Bundler that ships with Ruby 3.4.11 (2.6.9): a different one makes Bundler
switch versions under Passenger, which fails with "Could not find rails-8.1.4". The full checklist is in `CLAUDE.md`,
under "Before the first production deploy".

## More

`CLAUDE.md` has the current status, the decisions made so far, how this differs from the legacy app, and the
conventions to follow when adding a page.
