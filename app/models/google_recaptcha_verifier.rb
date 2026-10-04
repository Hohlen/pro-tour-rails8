require "net/http"
require "json"

# Asks Google whether a reCAPTCHA v2 "I'm not a robot" response token is genuine, via its siteverify API. Ported
# from legacy's ApplicationController#verify_google_recaptcha: split out of the controller, with the secret key
# in config (credentials in production, see config/environments/*.rb) instead of hardcoded, and a POST body
# instead of the secret in a query string (where it would end up in access logs).
#
# Never raises and never says yes by default: a missing token or secret, a network failure, a non-200 answer or
# unreadable JSON all log what happened and return false.
#
# The HTTP call is an injectable "poster" -- anything callable with (uri, form_hash) that returns an object with
# #code and #body -- so tests can feed it canned responses and never reach Google.
class GoogleRecaptchaVerifier
  SITEVERIFY_URI = URI("https://www.google.com/recaptcha/api/siteverify")

  NETWORK_ERRORS = [ Net::OpenTimeout, Net::ReadTimeout, SocketError, SystemCallError, IOError, EOFError,
                     OpenSSL::SSL::SSLError ].freeze

  DEFAULT_POSTER = lambda do |uri, form|
    request = Net::HTTP::Post.new(uri)
    request.set_form_data(form)
    Net::HTTP.start(uri.hostname, uri.port, use_ssl: true, open_timeout: 10, read_timeout: 10) do |http|
      http.request(request)
    end
  end

  class << self
    # The poster used when none is passed in. Real HTTP unless something replaces it, which only tests do -- to make
    # the controller's call to GoogleRecaptchaVerifier.verify reach a fake Google without passing a poster through.
    attr_writer :poster

    def poster
      @poster || DEFAULT_POSTER
    end

    def verify(response_token, poster: self.poster)
      new(response_token, poster: poster).verified?
    end
  end

  def initialize(response_token, poster: self.class.poster)
    @response_token = response_token
    @poster = poster
  end

  def verified?
    return false if @response_token.blank?

    secret = Rails.configuration.x.recaptcha.secret_key
    if secret.blank?
      Rails.logger.error "reCAPTCHA can't be verified: no secret key configured (recaptcha.secret_key in credentials)."
      return false
    end

    response = @poster.call(SITEVERIFY_URI, "secret" => secret, "response" => @response_token)
    unless response.code.to_i == 200
      Rails.logger.warn "Unexpected response from the Google reCAPTCHA API: HTTP #{response.code}"
      return false
    end

    success?(JSON.parse(response.body))
  rescue JSON::ParserError => e
    Rails.logger.warn "Unreadable response from the Google reCAPTCHA API: #{e.message}"
    false
  rescue *NETWORK_ERRORS => e
    Rails.logger.warn "Couldn't reach the Google reCAPTCHA API: #{e.class}: #{e.message}"
    false
  end

  # Public so it can be tested on its own: does an already-parsed API answer say the response was genuine?
  def success?(json)
    json.is_a?(Hash) && json["success"] == true
  end
end
