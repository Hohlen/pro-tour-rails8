# Site-wide constants, ported from legacy pro-tour-v2.0's config/environment.rb. Secrets (the Postmark server
# token, the reCAPTCHA secret key) live in encrypted credentials instead -- see config/environments/production.rb
# and, from Phase 3, GoogleRecaptchaVerifier.
SITE_TITLE = "Pro Tour Fantasy Golf"
PTFG_LLC_NAME = "KJ Businesses, LLC"
PTFG_URL = "https://www.ProTourFantasyGolf.com"
PTFG_ABBR = "PTFG"

ADMIN_EMAIL = "FantasyGolfCommissioner@gmail.com"
ADMIN_FULL_EMAIL_ADDRESS = "Fantasy Golf Commissioner <#{ADMIN_EMAIL}>"
# From address must be on our own domain, or Yahoo and Gmail reject the message.
SYSTEM_FULL_EMAIL_ADDRESS = "PTFG System <System@email.ProTourFantasyGolf.com>"

PAYPAL_ACCOUNT = ADMIN_EMAIL
VENMO_ACCOUNT = "@ProTour"

FACEBOOK_URL = "https://www.facebook.com/Pro-Tour-Fantasy-Golf-271919306650/"
TWITTER_URL = "https://twitter.com/ptfg"
WEBSITE_STATUS_URL = "https://forms.gle/MwD2FepZdDUkbJat8"

MIN_TEAMS = 30
MIN_LEAGUE_FEE = "$180"

# \A...\z rather than legacy's ^...$ throughout: Ruby's ^/$ match at every line break, so a value like
# "jane@example.com\nBcc: someone@else.com" would have passed a ^...$ check.
EMAIL_REG_EXP = /\A([^@\s]+)@((?:[-A-Za-z0-9]+\.)+[A-Za-z]{2,})\z/

# US phone number with area code, dashes required (so it's a clickable link in the email).
PHONE_NUMBER_REG_EXP = /\A\d{3}-\d{3}-\d{4}\z/

# MM/DD/YYYY, single-digit month/day allowed.
DATE_FORMAT_REG_EXP = /\A\d{1,2}\/\d{1,2}\/\d{4}\z/
