# Phase 0 stand-in for every page that hasn't been ported yet, so the nav bar's links all resolve. Each route in
# config/routes.rb passes its page title as a route default; delete this controller once no route uses it.
class PlaceholdersController < ApplicationController
  def show
    @page_title = params[:title]
  end
end
