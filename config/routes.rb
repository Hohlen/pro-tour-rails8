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

  # One URL per sort order, as in legacy. /leagues/index is what legacy's dropdown sent for "Default", so
  # bookmarks of it keep working.
  get "leagues" => "leagues#index", as: :leagues
  get "leagues/index" => redirect("/leagues")
  get "leagues/by_league_name" => "leagues#by_league_name", as: :leagues_by_league_name
  get "leagues/by_league_id" => "leagues#by_league_id", as: :leagues_by_league_id
  get "leagues/by_start_date" => "leagues#by_start_date", as: :leagues_by_start_date
  get "leagues/by_format" => "leagues#by_format", as: :leagues_by_format

  # Not in the nav: reached from emails to commissioners, from FAQs, or by announcement links.
  get "announcement" => "announcement#index", as: :announcement
  get "commissioners_corner" => "commissioners_corner#index", as: :commissioners_corner
  get "match_play_tournament" => "match_play_tournament#index", as: :match_play_tournament
  get "version" => "version#index", as: :version

  get "contact_us" => "contact_us#new", as: :contact_us
  post "contact_us" => "contact_us#create"
  get "contact_us/thank_you" => "contact_us#thank_you", as: :contact_us_thank_you
  # Legacy's form posted to /contact_us/send_email, and a GET there redirected to the form; old links keep working.
  get "contact_us/send_email" => redirect("/contact_us")

  # In the nav as "New League Request" (see layouts/_nav_bar). Legacy posted to /order_now/place_order, and its
  # /order_now/new was the same page as /order_now.
  get "order_now" => "order_now#new", as: :order_now
  post "order_now" => "order_now#create"
  get "order_now/new" => redirect("/order_now")
  get "order_now/place_order" => redirect("/order_now")
  get "order_now/thank_you" => "order_now#thank_you", as: :order_now_thank_you

  # Error pages, rendered via config.exceptions_app (see config/application.rb). `match ... via: :all` because
  # Rails replays the original request, whatever its HTTP method was, against these paths.
  match "/404", to: "errors#not_found", via: :all
  match "/422", to: "errors#unprocessable_entity", via: :all
  match "/500", to: "errors#internal_server_error", via: :all
end
