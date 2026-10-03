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

Planned phases: 1 static pages (Home with a Bootstrap 5 carousel, Game Formats, Features, Pricing, FAQs/Legal
accordions, Screenshots lightbox, the three Rules pages, Commissioner's Corner, Match Play, Announcement,
Version), 2 Leagues (flat-file listing -- legacy reads `league_listings.txt` from outside the repo, `../my-docs`
in dev), 3 Contact Us, 4 Order Now, 5 deployment (Kamal vs Capistrano + Passenger, still undecided; it decides
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
