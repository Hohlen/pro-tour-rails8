require "test_helper"

class GoogleRecaptchaVerifierTest < ActiveSupport::TestCase
  Response = Struct.new(:code, :body)

  # A poster that records its calls and answers with the given status and body.
  def poster(code: "200", body: '{"success": true}', calls: [])
    ->(uri, form) { calls << [ uri, form ]; Response.new(code, body) }
  end

  def verify(token = "a-token", **poster_options)
    GoogleRecaptchaVerifier.verify(token, poster: poster(**poster_options))
  end

  # --- the answer ---

  test "verified when Google says success" do
    assert verify(body: '{"success": true}')
  end

  test "not verified when Google says the response wasn't genuine" do
    assert_not verify(body: '{"success": false, "error-codes": ["invalid-input-response"]}')
  end

  test "success is only a literal true, not any truthy value" do
    assert_not verify(body: '{"success": "true"}')
    assert_not verify(body: '{"success": 1}')
    assert_not verify(body: "{}")
  end

  test "success? reads an already-parsed answer" do
    verifier = GoogleRecaptchaVerifier.new("a-token")

    assert verifier.success?({ "success" => true })
    assert_not verifier.success?({ "success" => false })
    assert_not verifier.success?({})
    assert_not verifier.success?(nil)
    assert_not verifier.success?([ "success" ])
  end

  # --- what's sent ---

  test "posts the secret and the response token to Google's siteverify endpoint, in the body" do
    calls = []
    verify("the-token", calls: calls)

    uri, form = calls.sole
    assert_equal "https://www.google.com/recaptcha/api/siteverify", uri.to_s
    assert_equal Rails.configuration.x.recaptcha.secret_key, form["secret"]
    assert_equal "the-token", form["response"]
    assert_nil uri.query, "the secret must not travel in the URL, where it would end up in logs"
  end

  # --- failing safe ---

  test "a blank token is rejected without calling Google" do
    calls = []

    assert_not verify("", calls: calls)
    assert_not verify(nil, calls: calls)
    assert_empty calls
  end

  test "a missing secret key is rejected without calling Google, and logged" do
    calls = []
    original = Rails.configuration.x.recaptcha.secret_key
    Rails.configuration.x.recaptcha.secret_key = nil
    log = capture_log { assert_not verify("a-token", calls: calls) }

    assert_empty calls
    assert_match(/no secret key configured/, log)
  ensure
    Rails.configuration.x.recaptcha.secret_key = original
  end

  test "a non-200 answer is rejected and logged" do
    log = capture_log { assert_not verify(code: "503", body: '{"success": true}') }

    assert_match(/Unexpected response.*HTTP 503/, log)
  end

  test "an unreadable body is rejected and logged" do
    log = capture_log { assert_not verify(body: "<html>Bad gateway</html>") }

    assert_match(/Unreadable response/, log)
  end

  test "network failures are rejected and logged, never raised" do
    [ Net::OpenTimeout, Net::ReadTimeout, SocketError, Errno::ECONNREFUSED, Errno::ECONNRESET, EOFError,
      OpenSSL::SSL::SSLError ].each do |error|
      failing = ->(_uri, _form) { raise error, "boom" }
      log = capture_log { assert_not GoogleRecaptchaVerifier.verify("a-token", poster: failing), error.name }

      assert_match(/Couldn't reach the Google reCAPTCHA API: #{error}/, log)
    end
  end

  test "the poster defaults to real HTTP and can be replaced, and put back, class-wide" do
    assert_same GoogleRecaptchaVerifier::DEFAULT_POSTER, GoogleRecaptchaVerifier.poster

    fake = poster
    GoogleRecaptchaVerifier.poster = fake
    begin
      assert_same fake, GoogleRecaptchaVerifier.poster
      assert GoogleRecaptchaVerifier.verify("a-token"), "verify uses the replaced poster when none is passed"
    ensure
      GoogleRecaptchaVerifier.poster = nil
    end
    assert_same GoogleRecaptchaVerifier::DEFAULT_POSTER, GoogleRecaptchaVerifier.poster
  end

  test "neither the token nor the secret is ever logged" do
    log = capture_log do
      verify("super-secret-token", code: "500")
      verify("super-secret-token", body: "nonsense")
    end

    assert_no_match(/super-secret-token/, log)
    assert_no_match(/#{Regexp.escape(Rails.configuration.x.recaptcha.secret_key)}/, log)
  end
end
