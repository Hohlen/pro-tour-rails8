# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A from-scratch Rails 8 rewrite of the Pro Tour Fantasy Golf marketing/ordering site (protourfantasygolf.com),
replacing the Rails 2.3 (LTS fork) app that lives in the sibling `pro-tour-v2.0` repo. That repo stays running
and untouched throughout this migration -- it's both the production app and the spec for this rewrite's
behavior and visual design (its pages were fully restyled just before this migration started), since nothing
else documents the `Order`/`EmailMsg` validation rules or the reCAPTCHA/Postmark integrations.

This is **not** the game itself: drafting, lineups and standings live in `fantasy-golf` /
`fantasy-golf-rails8`. This site is static-ish pages, a flat-file Leagues listing, and two plain-Ruby form
objects posted to controllers (Contact Us, Order Now).

Same migration pattern as `storks-now-rails8` (read its CLAUDE.md for the conventions this repo borrows) and
`fantasy-golf-rails8`. Like storks-now, this site has **no database at all**: Active Record, Active Storage and
Solid Cache/Queue/Cable are skipped entirely rather than ported.

## Current status

Phase 0 (scaffold) complete: Rails 8.1 on Ruby 3.4.11 with Propshaft, importmap, Turbo and Stimulus (no jQuery);
Bootstrap 5.3 vendored (`vendor/assets/stylesheets/bootstrap.min.css`, `app/assets/javascripts/vendor/`) with
Bootstrap Icons served from `public/vendor/bootstrap-icons/`; shared layout, nav bar, footer, sidebar logo card
(`layouts/_right_logo`), flash alerts, hero and button styles. (Pages not yet ported rendered a placeholder
until their phase; none are left.) Paths match legacy's exactly
(`/game_formats`, `/rules/one_and_done`, `/leagues/by_league_name`, ...) so bookmarks, `public/sitemap.xml` and
`public/robots.txt` (copied verbatim) stay valid.

Phase 1 (static pages) complete: Home (Bootstrap 5's native carousel), Game Formats, Features, Pricing, FAQs, Legal,
Screenshots, the three Rules pages, Commissioner's Corner, Match Play, Announcement and Version are all ported, with
the rendered text of each diffed against legacy's (the only differences are the ones listed below). Notes:
- FAQs and Legal share `shared/_accordion_item` and `accordion_controller.js` (Expand All/Collapse All; the buttons
  are `<button type="button">`, not `<a href="#">`, so Turbo Drive doesn't treat them as page visits). Panels are
  deliberately *not* tied together with `data-bs-parent`: legacy let several stay open, and Expand All needs that.
  Legal sections take an `icon:` and an `accent:` (blue = how the game works, green = privacy and accounts, red =
  conduct and technical liability, purple = disputes and the disclaimer); FAQs stay plain and numbered.
- Screenshots' lightbox is a native `<dialog>` (`gallery_lightbox_controller.js`, adapted from storks-now-rails8) with
  Colorbox's caption, "image X of N" counter and click-the-backdrop-to-close.
- `base.css` restores legacy's Bootstrap 3 base look on top of Bootstrap 5 (14px Helvetica, blue links that only
  underline on hover, 10px paragraph/list spacing, cards inheriting the page's purple). Without it every untouched
  line of text is bigger and looser than legacy's. `navbar.css` sets Bootstrap's `--bs-navbar-nav-link-padding-x`
  rather than padding on `.nav-link`, which Bootstrap's own more specific rule would override; the nav links now
  match legacy's positions and widths to the pixel. `html { scroll-padding-top }` keeps in-page links (the Rules
  pages' "More...") from landing behind the sticky navbar.
- `obfuscated_mail_to` reproduces Rails 2's `mail_to(..., encode: "hex")` (dropped in Rails 4).
- `AppVersion` replaces legacy's `config/initializers/app_version.rb`: reads the `REVISION`/`REVISION_TIME` files
  Capistrano writes, falling back to "Unknown" (and treating an empty or non-numeric `REVISION_TIME` as unknown rather
  than 1970); times are shown in the app's time zone. The files are gitignored.
- Error pages: `config.exceptions_app = routes`; `ErrorsController` renders 404 inside the site layout (replacing
  legacy's catch-all route and `home#unknown_request`) and serves `public/422.html`/`500.html` for the others.
  In development Rails still shows its own debug page, so the 404 page only appears in production-like runs.
  Its tests turn `show_detailed_exceptions` off; the 500/422 ones are controller tests because an integration GET
  of `/500` is answered by the static-file middleware before routing.
- `config.time_zone` is Central, as legacy's server was.
- Deliberate differences from legacy's content: FAQ #13's "Features" link now points at Features (legacy's pointed at
  Game Formats); Commissioner's Corner's stray empty `<b></b>` before "don't mark PTFG emails as spam" is fixed so
  the phrase is bold; Screenshots' hint says the viewer's X is "in the corner" (it's top-right here, bottom-right in
  Colorbox); legacy's commented-out blocks (old Commissioner's Corner items, the Prizes screenshot, Commish
  Home/League Settings entries) weren't ported -- they remain in `pro-tour-v2.0`. Legal's copy is verbatim,
  including its typos ("Therfore", "responsibily", "articipant").

Phase 2 (Leagues) complete: `LeagueListing` (one parsed line of `league_listings.txt`) and `LeagueDirectory` (loads the
file, picks which listings are shown, and sorts them five ways) in `app/models`, a one-action-per-ordering
`LeaguesController` (`/leagues`, `/leagues/by_league_name|by_league_id|by_start_date|by_format`, same URLs as legacy,
plus a redirect from `/leagues/index`, which legacy's dropdown sent for "Default"), and `sort_select_controller.js`
for the dropdown (legacy's inline `onchange`). The page is one blue table headed "<season> Leagues" with a league
count -- legacy had separate Public and Private tables; public leagues (the old $25 "FALL SERIES 1" one) are no longer
listed and the page no longer distinguishes public from private. The listed leagues are every listing flagged private
plus the "Summer" pool, whatever its flag (legacy's rule for its Private table). With the real 69-league file all five
orderings produced the same rows, order, links and tooltips as legacy's Private table.
- The page serves two audiences, people finding their league and people seeing how big PTFG is, so it has a live
  search box (`league_filter_controller.js`) and a stat line under the intro (league count, and `SITE_FOUNDED_YEAR`).
  The search filters the rows the server already rendered: every word typed must appear in a row's `data-search`
  (name, id, format, lowercased), the header count becomes "12 of 69 leagues", and the # column and zebra stripes are
  renumbered/re-striped over the visible rows (the table's `:nth-child` stripes would count hidden ones, so the
  stripe is a `lgRowAlt` class, not `.table-striped`). The box is rendered `hidden` and shown by the controller, so
  the page is complete without JavaScript. No game-formats stat: the site advertises four formats but listings use
  three.
- The header's season is `CurrentSeason.year`, which rolls over on Nov 1; the table isn't filtered by season, so a
  file that still lists earlier seasons' leagues shows them under that heading.
- The file's location is `config.x.league_listings_path`: `../my-docs/league_listings.txt` in development (the
  checkout next to this one), `test/fixtures/files/league_listings.txt` in test, and in production the
  `LEAGUE_LISTINGS_PATH` env var, defaulting to legacy's Capistrano-relative `../../../league_listings.txt`, which
  from `releases/<timestamp>/` is `/home/admin/league_listings.txt` on the server (under Passenger an env var has to be
  set with `passenger_env_var` in the site config).
- Names sort as plain case-sensitive strings, as legacy's did ("BIG BOYS LEAGUE" before "Bottom Feeders").
- No fragment caching, unlike legacy's `cache(controller, action)`: the page is ~70 parsed lines, and a cache keyed
  only on the action served stale rows until someone cleared it whenever the file was edited.
- Differences from legacy: the summer pool appears once. Legacy added it to the private list even when the file
  already flagged it private (as the dev copy does), so it listed it twice (70 rows vs 69). A missing or unreadable
  file shows an empty table and logs a warning; legacy printed to stdout, and on a read error called `exit`, killing
  the server. A line that doesn't parse (wrong field count, bad date) is skipped and logged instead of raising.

Phase 3 (Contact Us) complete: `ContactUsForm` (plain-Ruby form object, legacy's `EmailMsg` with the same method
names), `GoogleRecaptchaVerifier` (service object around the siteverify call; its HTTP is an injectable "poster" so
tests never reach Google, and it fails closed -- a missing token or secret, network error, non-200 or bad JSON all log
and return false), `ContactUsMailer#contact_message` (named that, not legacy's `message`, which collides with
`ActionMailer::Base#message`), `ContactUsController` (`new`/`create`/`thank_you`), and `recaptcha_controller.js`.
`test_helper.rb` gained `stub_class_method` (Minitest 6 has no `stub`) and `capture_log`. Notes:
- **Needs a secret before the live send works in production**: `recaptcha.secret_key` in encrypted credentials
  (`bin/rails credentials:edit`; the value is in legacy's `ApplicationController#verify_google_recaptcha`). Until
  then every verification fails and the form says "Unexpected error". The site key is public and sits in
  `config/environments/production.rb`; development and test use **Google's published always-pass test keys**
  (the widget says "for testing purposes only"), so the whole flow -- real widget, real siteverify call, real mailer --
  runs locally without the real secret. Production's `ActionMailer` also needs `postmark.server_token`.
- The reCAPTCHA widget is rendered explicitly by the Stimulus controller, not by Google's auto-render, which only
  fires when its script first executes -- under Turbo Drive that wouldn't be on this page. The page sets
  `turbo-cache-control: no-cache` so a snapshot with a rendered widget is never replayed into itself. The form is a
  normal Turbo form (the 422 re-render works; `data-turbo-submits-with` stops a double submit), unlike storks-now-
  rails8's, which forces a full page reload and a native submit instead. Verified in a browser, including arriving by
  Turbo visit from another page.
- The mail is plain text (legacy sent HTML, which collapsed the visitor's line breaks), To the commissioner, From the
  system address, Reply-To the visitor, with Postmark's stream/tag headers.
- Hardening beyond legacy: the honeypot field is checked first, so a bot learns nothing from validation messages;
  a subject is squished to one line, so a hand-crafted POST can't inject headers; the from address is matched with
  `\A...\z` (legacy's `^...$` accepted "valid@x.com\nBcc: ..."); a POST with no form fields gets the normal "enter all
  fields" message, not a 400; Google being unreachable shows the "Unexpected error" message, not a 500. The error text
  fixes legacy's "via by sending".

Phase 4 (Order Now) complete, at legacy's paths (`/order_now`, `POST /order_now`, `/order_now/thank_you`; legacy's
`/order_now/new` and a GET of `/order_now/place_order` redirect to the form). Linked from the nav as "New League
Request" (legacy had that link commented out whenever it didn't want more leagues, since total leagues must stay at
120 or less; to hide it again, delete the one line in `layouts/_nav_bar.html.erb`). `Order` (plain-Ruby form object, legacy's
`OrderNowController::Order` with the same method names but keyword arguments), `OrderNowController`
(`new`/`create`/`thank_you`), `OrderMailer#order_confirmation` (legacy's `order`), views under `order_now/` with a
`_field` partial, `order_now.css`. It reuses Phase 3's `GoogleRecaptchaVerifier`, `recaptcha_controller.js` and the
`ct*` form/thank-you styles (`.ctForm` now styles `.form-select` too). Notes:
- Same validation order and wording as legacy: required fields, email, password with a space, missing reCAPTCHA
  token, failed verification. Only heard_about_us, your_name and your_email are required.
- The mail is the same HTML as legacy (To the requester, BCC and Reply-To the commissioner, Postmark tag
  "New League Request", PayPal/Venmo/check instructions). Additional comments keep their line breaks (escaped first,
  then `simple_format`); legacy's HTML collapsed them.
- Differences from legacy: no `SanitizeHelper` (ERB escapes everything on output, and the one-line fields are
  squished so a hand-crafted POST can't put extra lines in the mail); the email is matched with `\A...\z`; the
  thank-you page redirects home when reloaded or visited directly (legacy rendered the home page at that URL); the
  flash says "has been submitted" (legacy: "been submitted"); the failed-reCAPTCHA message links to Contact Us; the
  intro's "For 2026, ..." notice is still hard-coded text, as in legacy, so update it each season.
- Needs the same production secrets as Contact Us (`recaptcha.secret_key`, `postmark.server_token`).

Phase 5 (deployment): **Capistrano + Passenger**, set up but not yet used (`Capfile`, `config/deploy.rb`,
`config/deploy/production.rb`; Capistrano 3.20.1, whose version is pinned in the Gemfile and must match the `lock`
line in `deploy.rb`). The Kamal/Docker scaffold (Dockerfile, `.kamal/`, `bin/kamal`, `bin/thrust`, ...) was removed, and
the `kamal`/`thruster` Gemfile entries are commented out. It deploys to `/home/admin/protourfantasygolf.com` (the same
directory name legacy uses) on a **new server for the Rails 8 apps, not legacy's VPS**; its address in
`config/deploy/production.rb` is still the placeholder `w.x.y.z` (replace it with the new server's IP -- DNS still
points at the old server at first), so a deploy can't land on legacy's machine by accident. Rails 8 specifics:
`capistrano/rails/assets` precompiles Propshaft's assets, there is no `capistrano/rails/migrations` since there is no
database, and `config/master.key` is a linked file the deploy requires to already exist in `shared/config/` on the
server. Still to do on the server (one time): Ruby 3.4.11 under RVM, `master.key`, the league listings file, and a
Passenger site for `current/public`.

Conventions worth knowing before porting a page:
- Legacy's Bootstrap 3 markup converts mechanically: `col-sm-*` -> `col-md-*` (Bootstrap 5's `sm` is 576px, its
  `md` 768px is what matched Bootstrap 3's `sm`), `hidden-xs` -> `d-none d-md-block`, `panel` -> `card`,
  `data-toggle` -> `data-bs-toggle`, Glyphicons -> Bootstrap Icons.
- Legacy CSS class names (`hmHero-*`, `gfCard-*`, `ssCard-*`, `lgTable*`, `prPrice*`, `faqItem-*`, `ct*`) are kept
  so views port mechanically; the styles are split into one file per concern under `app/assets/stylesheets/`.
- Views set their heading/title with `content_for(:page_heading)` / `content_for(:title)` (the layout renders
  them), not legacy's `page_title` helper.
- Legacy dead code is not ported: the `delivery_areas` helper, `get_yield_style`, `home/commishs_corner.rhtml`
  (unrouted), the unused datepicker/magnific-popup plugins, and the `hash.rb`/`string.rb`/`sanitize_patch.rb`
  Rails 2 shims.
- `CurrentSeason.year` replaces legacy's boot-time `CURRENT_SEASON` constant (which went stale in a long-running
  server after the Nov 1 rollover).
- `ApplicationController` deliberately has no `allow_browser` check, same as storks-now-rails8.
- `page_title_tag` builds the title with `safe_join`: `content_for` returns an already-escaped SafeBuffer, and plain
  string interpolation made the layout escape it twice ("Commissioner&#39;s Corner" in the browser tab).
- To compare a page against legacy, run `pro-tour-v2.0` on a spare port (`ruby script/server -p 3055`) next to this
  app on 3002; `preview_start` looks up launch configs from the session's original directory, so start both from
  the shell instead.

## Local setup

No database, no setup beyond `bundle install`. Secrets (the Postmark server token and the reCAPTCHA secret key) go in
encrypted credentials (`bin/rails credentials:edit`), not plaintext config -- unlike legacy, which has them as plain
constants. The values are in legacy's `config/environments/production.rb` and
`ApplicationController#verify_google_recaptcha`. Neither is needed in development or test (see Phase 3 above).

## Before the first production deploy

Things that work locally but won't in production until someone does them (development and test use Google's always-pass
reCAPTCHA test keys and a captured-mail delivery method, so none of this shows up as a failure on a dev machine):

- [x] **`recaptcha.secret_key`** in encrypted credentials (`bin/rails credentials:edit`). Done: set to legacy's value
  and accepted by Google (checked 2026-10-09). Without it every Contact Us and Order Now submission ends in
  "Unexpected error".
- [x] **`postmark.server_token`** in encrypted credentials. Done: set to legacy's `POSTMARK_SERVER_TOKEN` (checked
  2026-10-09). Without it production can't send mail.
- [ ] **`config/master.key`** is gitignored and was generated on this machine. Back it up somewhere safe -- without it
  the encrypted credentials are unreadable -- and put a copy at `/home/admin/protourfantasygolf.com/shared/config/master.key`
  on the server (Capistrano links it into every release and stops the deploy if it's missing).
- [ ] **The league listings file**: put `league_listings.txt` at `/home/admin/league_listings.txt` on the server (what
  legacy's relative default resolves to under Capistrano), or set `LEAGUE_LISTINGS_PATH` with `passenger_env_var`.
- [ ] **The server address** in `config/deploy/production.rb` (placeholder `w.x.y.z`), once the new server exists.
- [ ] **`config.action_mailer.default_url_options`** host in `config/environments/production.rb` (currently
  `protourfantasygolf.com`), plus `force_ssl`/`assume_ssl` and `config.hosts` for the real domain.
- [ ] Legacy `pro-tour-v2.0` stays live and untouched until cutover.

To see which credentials are set (prints only true/false, never a value):

```bash
RAILS_ENV=production bin/rails runner 'puts({ recaptcha_secret_key: Rails.application.credentials.dig(:recaptcha, :secret_key).present?, postmark_server_token: Rails.application.credentials.dig(:postmark, :server_token).present? }.inspect)'
```

## Commands

```bash
# This machine's default Ruby (via rbenv) predates Rails 8 -- everything in this repo needs 3.4.11, which
# .ruby-version already pins; RBENV_VERSION= only matters if running commands from outside the repo dir.
bin/rails server          # dev server on 3002, Puma's default (legacy owns 3000, fantasy-golf-rails8 3001, storks-now-rails8 3003)
bin/rails test
bin/rails console
```
