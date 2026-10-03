require "test_helper"

class LegalTest < ActionDispatch::IntegrationTest
  test "lists the twelve sections, collapsed and un-numbered" do
    get legal_path

    assert_response :success
    assert_select "title", /\ALegal Terms and Conditions \| Pro Tour Fantasy Golf \d{4}\z/
    assert_select "h2#pageTitle", "Legal Terms & Conditions"
    assert_select ".faqItem", 12
    assert_select ".faqItem-number", count: 0
    assert_select "a.faqItem-toggle.collapsed", 12
    assert_select ".faqItem-question", text: "Tournament Schedules"
    assert_select ".faqItem-question", text: "Disclaimer"
  end

  test "every section has an icon badge and an accent color, grouped by theme" do
    get legal_path

    assert_select ".faqItem.faqItem--accent", 12
    assert_select ".faqItem-icon i.bi", 12
    # How the game works / privacy and accounts / conduct and technical liability / decisions and disclaimer.
    assert_select ".faqItem--blue", 4
    assert_select ".faqItem--green", 3
    assert_select ".faqItem--red", 3
    assert_select ".faqItem--purple", 2
    assert_select ".faqItem--blue #heading1 .bi-calendar-event"
    assert_select ".faqItem--purple #heading12 .bi-info-circle"
  end

  test "the FAQs page stays plain: numbered badges, no accent colors" do
    get faqs_path

    assert_select ".faqItem--accent", count: 0
    assert_select ".faqItem-icon", count: 0
  end

  test "fills in the site name and abbreviation" do
    get legal_path

    assert_select ".hmHero-lead", /governing all Pro Tour Fantasy Golf leagues/
    assert_select "#collapse1", /PTFG reserves the\s+right/
    assert_select "#collapse5", /resolved by Pro Tour Fantasy Golf based on its/
  end

  test "Scoring links out to the PGA Tour" do
    get legal_path

    assert_select "#collapse4 a[href='http://www.pgatour.com']", "PGA Tour"
  end

  test "has the same Expand All and Collapse All controls as FAQs" do
    get legal_path

    assert_select "[data-controller='accordion'] button[data-action='accordion#expandAll']", "Expand All"
    assert_select "[data-controller='accordion'] button[data-action='accordion#collapseAll']", "Collapse All"
  end
end
