require "test_helper"

class SitemapTest < ActionDispatch::IntegrationTest
  PREFIX = "https://www.protourfantasygolf.com".freeze

  def locs
    doc = Nokogiri::XML(File.read(Rails.root.join("public/sitemap.xml"))) { |config| config.strict }
    doc.remove_namespaces!.xpath("//loc").map(&:text)
  end

  test "sitemap.xml is well-formed and lists no page twice" do
    assert_equal locs.uniq, locs
  end

  test "every page in the sitemap exists on the site" do
    locs.each do |loc|
      assert loc.start_with?(PREFIX), "#{loc} is not on #{PREFIX}"
      get loc.delete_prefix(PREFIX).presence || "/"
      assert_response :success, "#{loc} did not return 200"
    end
  end
end
