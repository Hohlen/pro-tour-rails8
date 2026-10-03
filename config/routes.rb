Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Flat named routes, not `resources` -- matches legacy pro-tour-v2.0's flat, non-RESTful page set. Paths are
  # kept identical to the legacy app's (its default :controller/:action route produced /game_formats,
  # /rules/one_and_done, /leagues/by_league_name, ...) so bookmarks, sitemap.xml and robots.txt stay valid.
  root "home#index"

  get "game_formats" => "game_formats#index", as: :game_formats
  get "features" => "features#index", as: :features
  get "screenshots" => "screenshots#index", as: :screenshots
  get "pricing" => "pricing#index", as: :pricing
  get "faqs" => "faqs#index", as: :faqs
  get "legal" => "legal#index", as: :legal

  get "rules/one_and_done" => "rules#one_and_done", as: :rules_one_and_done
  get "rules/let_it_ride" => "rules#let_it_ride", as: :rules_let_it_ride
  get "rules/pick_3_classic" => "rules#pick_3_classic", as: :rules_pick_3_classic

  # Not in the nav: reached from emails to commissioners, from FAQs, or by announcement links.
  get "announcement" => "announcement#index", as: :announcement
  get "commissioners_corner" => "commissioners_corner#index", as: :commissioners_corner
  get "match_play_tournament" => "match_play_tournament#index", as: :match_play_tournament
  get "version" => "version#index", as: :version

  # Still Phase 0 placeholders until their phases land (Phase 2: Leagues, Phase 3: Contact Us). Replace each
  # route's `to:`/`defaults:` when its phase ports the page; delete PlaceholdersController once none are left.
  {
    leagues: "Leagues",
    contact_us: "Contact Us"
  }.each do |path, title|
    get path.to_s => "placeholders#show", as: path, defaults: { title: title }
  end

  # Error pages, rendered via config.exceptions_app (see config/application.rb). `match ... via: :all` because
  # Rails replays the original request, whatever its HTTP method was, against these paths.
  match "/404", to: "errors#not_found", via: :all
  match "/422", to: "errors#unprocessable_entity", via: :all
  match "/500", to: "errors#internal_server_error", via: :all
end
