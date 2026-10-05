# The Order Now (start a new league) form's fields and validation rules, as a plain Ruby object. Ported from
# legacy's OrderNowController::Order (same method names, so its tests port across), pulled into its own file and
# given keyword arguments in place of thirteen positional ones.
#
# Only heard_about_us, your_name and your_email are required; everything else is a preliminary answer that can
# still change before the league is set up.
class Order
  HEARD_ABOUT_US_CHOICES = [ "Google", "Other Search Engine", "Friend / Family", "Facebook", "Twitter", "Played Before",
                             "Website Message Board", "Other" ].freeze
  GAME_FORMATS = [ "One & Done", "Two & Thru", "Pick 3 Classic (Weekend Sub)", "Let It Ride (No Weekend Sub)" ].freeze
  TIME_ZONES = %w[Eastern Central Mountain Pacific Other].freeze

  FIELDS = %i[heard_about_us desired_league_name game_format start_tournament end_tournament number_of_segments
              league_time_zone projected_league_size league_password additional_comments your_name your_email
              your_phone].freeze

  # Typed into a multi-line box, so line breaks are kept. Every other field is one line.
  MULTI_LINE_FIELDS = %i[additional_comments].freeze

  attr_reader(*FIELDS)

  def initialize(**attributes)
    FIELDS.each do |field|
      value = attributes[field].to_s
      # squish folds any newlines in a one-line field into spaces, so a hand-crafted POST can't smuggle extra
      # lines into the email these values are printed in.
      instance_variable_set(:"@#{field}", MULTI_LINE_FIELDS.include?(field) ? value.strip : value.squish)
    end
  end

  def all_required_fields_entered?
    !heard_about_us_blank? && !your_name_blank? && !your_email_blank?
  end

  def heard_about_us_blank?
    heard_about_us.empty?
  end

  def your_name_blank?
    your_name.empty?
  end

  def your_email_blank?
    your_email.empty?
  end

  def email_address_valid?
    EMAIL_REG_EXP.match?(your_email)
  end

  # Despite the name (kept from legacy), this is whether the password contains a whitespace character -- not
  # whether a password was entered at all.
  def league_password_contains_password?
    league_password.match?(/\s/)
  end

  def your_email_has_error?
    your_email_blank? || !email_address_valid?
  end
end
