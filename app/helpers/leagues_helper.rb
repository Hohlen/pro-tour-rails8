module LeaguesHelper
  # The "Sort By" dropdown's choices, in legacy's order, each with the path that shows that ordering.
  SORT_CHOICES = [
    [ "Default", :default ],
    [ "League Name", :league_name ],
    [ "League ID", :league_id ],
    [ "Start Date", :start_date ],
    [ "Format", :league_format ]
  ].freeze

  def league_sort_path(order)
    case order
    when :default then leagues_path
    when :league_name then leagues_by_league_name_path
    when :league_id then leagues_by_league_id_path
    when :start_date then leagues_by_start_date_path
    when :league_format then leagues_by_format_path
    end
  end

  def league_sort_options
    SORT_CHOICES.map { |label, order| [ label, league_sort_path(order) ] }
  end

  # Under the League ID ordering the name column shows each league's id rather than its name.
  def league_sort_by_id?
    @order == :league_id
  end
end
