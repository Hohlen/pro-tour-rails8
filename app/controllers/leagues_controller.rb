class LeaguesController < ApplicationController
  # The five orderings the "Sort By" dropdown offers, one action each so each has its own URL (as in legacy, and
  # robots.txt asks crawlers to skip the by_* ones). index is the default.
  def index
    show :default
  end

  def by_league_name
    show :league_name
  end

  def by_league_id
    show :league_id
  end

  def by_start_date
    show :start_date
  end

  def by_format
    show :league_format
  end

  private

  def show(order)
    @order = order
    @leagues = LeagueDirectory.load.leagues(order)
    render :index
  end
end
