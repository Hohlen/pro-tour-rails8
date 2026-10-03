require "test_helper"

class AnnouncementTest < ActionDispatch::IntegrationTest
  test "renders the dated announcement with a red heading" do
    get announcement_path

    assert_response :success
    assert_select "title", /\AImportant Announcement \| Pro Tour Fantasy Golf \d{4}\z/
    assert_select "h2#pageTitle.ptfgRed", "Important Announcement (3/21/2020)"
    assert_select "b", /To: All \d{4} PTFG Participants/
  end

  test "other pages' headings don't get the red class" do
    get faqs_path

    assert_select "h2#pageTitle.ptfgRed", count: 0
  end
end
