require "test_helper"

class FaqsTest < ActionDispatch::IntegrationTest
  test "lists the thirteen questions, numbered, each collapsed with its answer wired to its trigger" do
    get faqs_path

    assert_response :success
    assert_select "title", /\AFAQs \| Pro Tour Fantasy Golf \d{4}\z/
    assert_select ".faqItem", 13
    assert_select ".faqItem-number", count: 13
    assert_select ".faqItem-number", text: "13"
    (1..13).each do |id|
      assert_select "a.faqItem-toggle.collapsed[href='#collapse#{id}'][aria-controls='collapse#{id}'][aria-expanded='false']"
      assert_select "#collapse#{id}.collapse[aria-labelledby='heading#{id}']"
      assert_select "#heading#{id}"
    end
  end

  test "Expand All and Collapse All are real buttons wired to the accordion controller" do
    get faqs_path

    assert_select "[data-controller='accordion']" do
      assert_select "button[type='button'][data-action='accordion#expandAll']", "Expand All"
      assert_select "button[type='button'][data-action='accordion#collapseAll']", "Collapse All"
    end
  end

  test "the last answer's Features link goes to Features (legacy's pointed at Game Formats)" do
    get faqs_path

    assert_select "#collapse13 a[href='#{features_path}']", "Features"
    assert_select "#collapse13 a[href='#{game_formats_path}']", "Game Formats"
    assert_select "#collapse13 a[href='#{legal_path}']", "Legal Terms & Conditions"
  end

  test "the match play answer links to the match play page" do
    get faqs_path

    assert_select "#collapse5 a[href='#{match_play_tournament_path}']", "here"
  end
end
