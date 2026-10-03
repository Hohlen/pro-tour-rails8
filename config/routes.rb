Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Flat named routes, not `resources` -- matches legacy pro-tour-v2.0's flat, non-RESTful page set. Paths are
  # kept identical to the legacy app's (its default :controller/:action route produced /game_formats,
  # /rules/one_and_done, /leagues/by_league_name, ...) so bookmarks, sitemap.xml and robots.txt stay valid.
  root "home#index"

  # Phase 0 placeholders: every nav page renders PlaceholdersController#show until its real controller lands
  # (Phase 1: static pages, Phase 2: Leagues, Phase 3: Contact Us). Replace each route's `to:`/`defaults:` when
  # its phase ports the page; delete PlaceholdersController once none are left.
  {
    game_formats: "Game Formats",
    features: "Features",
    screenshots: "Screenshots",
    pricing: "Pricing",
    leagues: "Leagues",
    faqs: "FAQs",
    legal: "Legal Terms & Conditions",
    contact_us: "Contact Us"
  }.each do |path, title|
    get path.to_s => "placeholders#show", as: path, defaults: { title: title }
  end
end
