# The new cPanel server for the Rails 8 apps (not the VPS legacy pro-tour-v2.0 runs on). Deployed by IP address until
# protourfantasygolf.com's DNS is moved over to it.
server "68.183.164.91", user: "ptfghost", roles: %w[web app], primary: true

set :stage, :production
set :rails_env, :production
