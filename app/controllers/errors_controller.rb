# Rendered by Rails' exceptions_app (config/application.rb routes error statuses here). Replaces legacy's
# catch-all route and home#unknown_request. 404 gets the full site layout, like legacy's page did; 422 and 500
# fall back to the static pages in public/ so a failure inside the layout itself can't take the error page down.
class ErrorsController < ApplicationController
  # The original request is replayed here, so a POST that failed CSRF verification (the usual cause of a 422)
  # would fail verification again if this controller checked it.
  skip_forgery_protection

  def not_found
    render status: :not_found
  end

  def unprocessable_entity
    render file: Rails.public_path.join("422.html"), layout: false, status: :unprocessable_entity
  end

  def internal_server_error
    render file: Rails.public_path.join("500.html"), layout: false, status: :internal_server_error
  end
end
