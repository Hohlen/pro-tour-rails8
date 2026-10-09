require "test_helper"

class AppVersionTest < ActiveSupport::TestCase
  test "everything is Unknown (and deployed_at is the boot time) when Capistrano's files aren't there" do
    Dir.mktmpdir do |root|
      version = AppVersion.new(root)

      assert_equal "Unknown", version.revision
      assert_equal "Unknown", version.revision_time
      assert_equal AppVersion::BOOTED_AT, version.deployed_at
    end
  end

  test "reads the revision, its commit time, and the deploy time from the release's files" do
    Dir.mktmpdir do |root|
      File.write(File.join(root, "REVISION"), "4e894c0\n")
      File.write(File.join(root, "REVISION_TIME"), "1759363200\n")
      deployed = Time.utc(2025, 10, 2, 12, 0, 0)
      File.utime(deployed, deployed, File.join(root, "REVISION"))

      version = AppVersion.new(root)

      assert_equal "4e894c0", version.revision
      assert_equal Time.utc(2025, 10, 2), version.revision_time
      assert_equal deployed, version.deployed_at
    end
  end

  test "an empty or non-numeric REVISION_TIME is Unknown, not 1970" do
    Dir.mktmpdir do |root|
      File.write(File.join(root, "REVISION"), "4e894c0\n")

      [ "", "\n", "not a number", "0" ].each do |contents|
        File.write(File.join(root, "REVISION_TIME"), contents)

        assert_equal "Unknown", AppVersion.new(root).revision_time, "for #{contents.inspect}"
      end
    end
  end

  test "times are in the app's time zone" do
    Dir.mktmpdir do |root|
      File.write(File.join(root, "REVISION"), "4e894c0\n")
      File.write(File.join(root, "REVISION_TIME"), "1759363200\n")

      version = AppVersion.new(root)

      assert_equal Time.zone, version.revision_time.time_zone
      assert_equal Time.zone, version.deployed_at.time_zone
    end
  end

  test "current is built from the Rails root and memoized" do
    assert_same AppVersion.current, AppVersion.current
  end
end
