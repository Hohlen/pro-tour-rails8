# The new server for the Rails 8 apps -- not the VPS legacy pro-tour-v2.0 runs on. Deploy by IP address at first,
# since DNS still points at the old server. Replace w.x.y.z with that IP; until then a deploy fails at connect (it
# isn't a real address) instead of landing on the wrong machine.
server "w.x.y.z", user: "root", roles: %w[web app], primary: true

set :stage, :production
set :rails_env, :production
