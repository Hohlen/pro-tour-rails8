ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Minitest 6 dropped Minitest::Mock and Object#stub from core, so this swaps a class method out for the length of
    # a block: it returns +return_value+, or -- to see what it was called with -- whatever the callable passed as
    # +with:+ returns. Used to stub GoogleRecaptchaVerifier.verify so tests never reach Google.
    #
    #   stub_class_method(GoogleRecaptchaVerifier, :verify, true) { post ... }
    #   stub_class_method(GoogleRecaptchaVerifier, :verify, with: ->(token) { seen << token; true }) { post ... }
    def stub_class_method(klass, method_name, return_value = nil, with: nil)
      original = klass.method(method_name)
      klass.define_singleton_method(method_name) { |*args| with ? with.call(*args) : return_value }
      yield
    ensure
      klass.define_singleton_method(method_name, original)
    end

    # Runs the block with Rails.logger writing to a StringIO and returns what was logged.
    def capture_log
      original = Rails.logger
      log = StringIO.new
      Rails.logger = ActiveSupport::Logger.new(log)
      yield
      log.string
    ensure
      Rails.logger = original
    end
  end
end
