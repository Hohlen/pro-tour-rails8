# The new cPanel server for the Rails 8 apps. Deploy by IP address, not by protourfantasygolf.com, so a
# DNS change (a repoint, a Cloudflare proxy) can never send a deploy to the wrong machine.
server "68.183.164.91", user: "ptfghost", roles: %w[web app], primary: true

set :stage, :production
set :rails_env, :production
