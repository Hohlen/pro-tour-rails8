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

Phase 0 (scaffold) complete: Rails 8.1 on Ruby 3.3.5 with Propshaft, importmap, Turbo and Stimulus (no jQuery);
Bootstrap 5.3 vendored (`vendor/assets/stylesheets/bootstrap.min.css`, `app/assets/javascripts/vendor/`) with
Bootstrap Icons served from `public/vendor/bootstrap-icons/`; shared layout, nav bar, footer, sidebar logo card
(`layouts/_right_logo`), flash alerts, hero and button styles. Every nav page except Home renders
`PlaceholdersController#show` until its phase ports it (see `config/routes.rb`). Paths match legacy's exactly
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
  Capistrano writes, falling back to "Unknown". Phase 5 may change the source if deployment moves to Kamal.
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
  `LEAGUE_LISTINGS_PATH` env var, defaulting to legacy's Capistrano-relative `../../../league_listings.txt`. **Phase 5
  must settle this**: under Docker/Kamal the file needs a mounted volume and the env var.
- Names sort as plain case-sensitive strings, as legacy's did ("BIG BOYS LEAGUE" before "Bottom Feeders").
- No fragment caching, unlike legacy's `cache(controller, action)`: the page is ~70 parsed lines, and a cache keyed
  only on the action served stale rows until someone cleared it whenever the file was edited.
- Differences from legacy: the summer pool appears once. Legacy added it to the private list even when the file
  already flagged it private (as the dev copy does), so it listed it twice (70 rows vs 69). A missing or unreadable
  file shows an empty table and logs a warning; legacy printed to stdout, and on a read error called `exit`, killing
  the server. A line that doesn't parse (wrong field count, bad date) is skipped and logged instead of raising.

Planned phases: 3 Contact Us, 4 Order Now, 5 deployment (Kamal vs Capistrano + Passenger, still undecided; it decides
where the leagues file lives in production).

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

No database, no setup beyond `bundle install`. Secrets (the Postmark server token and, from Phase 3, the
reCAPTCHA secret key) go in encrypted credentials (`bin/rails credentials:edit`), not plaintext config -- unlike
legacy, which has them as plain constants. The values are in legacy's `config/environments/production.rb` and
`ApplicationController#verify_google_recaptcha`.

## Commands

```bash
# This machine's default Ruby (via rbenv) predates Rails 8 -- everything in this repo needs 3.3.5, which
# .ruby-version already pins; RBENV_VERSION= only matters if running commands from outside the repo dir.
bin/rails server -p 3002   # dev server (3002 -- legacy owns 3000, fantasy-golf-rails8 3001, storks-now-rails8 3003)
bin/rails test
bin/rails console
```
