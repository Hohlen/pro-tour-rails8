# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.0"

# vendor/assets/stylesheets/bootstrap.min.css lives outside app/assets/stylesheets on purpose: Propshaft's :app
# stylesheet bundle concatenates every file under app/assets/stylesheets (subdirectories included), so a copy
# in there would load a second time after all our own overrides and win same-specificity ties against them.
# Same setup as storks-now-rails8 and fantasy-golf-rails8.
Rails.application.config.assets.paths << Rails.root.join("vendor/assets/stylesheets")
