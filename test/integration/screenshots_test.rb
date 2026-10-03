require "test_helper"

class ScreenshotsTest < ActionDispatch::IntegrationTest
  test "shows ten screenshot cards, each linking to its full-size image" do
    get screenshots_path

    assert_response :success
    assert_select "title", /\ASample Screenshots \| Pro Tour Fantasy Golf \d{4}\z/
    assert_select "h2#pageTitle", "Screenshots"
    assert_select "a.ssCard", 10
    assert_select "a.ssCard[data-action='gallery-lightbox#open']", 10
    assert_select "a.ssCard[href*='/assets/screenshots/Standings']"
    (0..9).each { |index| assert_select "a.ssCard[data-index='#{index}']", 1 }
  end

  test "the lightbox gets the image list as JSON, in grid order, with captions" do
    get screenshots_path

    json = css_select("[data-controller='gallery-lightbox']").first["data-gallery-lightbox-images-value"]
    images = JSON.parse(json)
    assert_equal 10, images.length
    assert_equal "Weekly Results", images.first["caption"]
    assert_equal "Talk Smack In The League Clubhouse", images.last["caption"]
    assert(images.all? { |image| image["src"].start_with?("/assets/screenshots/") })
  end

  test "has a dialog with close, previous, next, caption and counter targets" do
    get screenshots_path

    assert_select "dialog.ssLightbox[data-gallery-lightbox-target='dialog']" do
      assert_select "[data-gallery-lightbox-target='image']"
      assert_select "[data-gallery-lightbox-target='caption']"
      assert_select "[data-gallery-lightbox-target='counter']"
      assert_select "button[data-action='gallery-lightbox#close']"
      assert_select "button[data-action='gallery-lightbox#prev']"
      assert_select "button[data-action='gallery-lightbox#next']"
    end
  end

  test "the Prizes screenshot stays out, as in legacy" do
    get screenshots_path

    assert_select "a.ssCard[title='Prizes']", count: 0
  end
end
