require "test_helper"

class CurrentSeasonTest < ActiveSupport::TestCase
  test "is this year until October 31" do
    travel_to Time.zone.local(2026, 10, 31, 12) do
      assert_equal "2026", CurrentSeason.year
    end
  end

  test "rolls over to next year on November 1" do
    travel_to Time.zone.local(2026, 11, 1, 0, 1) do
      assert_equal "2027", CurrentSeason.year
    end
  end

  test "is re-evaluated on every call rather than frozen at boot" do
    travel_to Time.zone.local(2026, 6, 1) do
      assert_equal "2026", CurrentSeason.year
    end
    travel_to Time.zone.local(2026, 12, 1) do
      assert_equal "2027", CurrentSeason.year
    end
  end
end
