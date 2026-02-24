require "test_helper"
require "rake"

class SetupRakeTest < ActiveSupport::TestCase
  setup do
    Rails.application.load_tasks unless Rake::Task.task_defined?("setup:admin")
  end

  test "creates a new admin user" do
    ENV["NAME"]     = "Admin User"
    ENV["EMAIL"]    = "admin@example.com"
    ENV["PASSWORD"] = "password123"

    assert_difference "User.count", 1 do
      Rake::Task["setup:admin"].invoke
    end

    user = User.find_by(email_address: "admin@example.com")
    assert_equal "Admin User", user.name
    assert_equal "Etc/UTC", user.timezone
    assert user.authenticate("password123")
  ensure
    Rake::Task["setup:admin"].reenable
    ENV.delete("NAME")
    ENV.delete("EMAIL")
    ENV.delete("PASSWORD")
  end

  test "updates existing user idempotently" do
    existing = users(:one)
    ENV["NAME"]     = "Updated Name"
    ENV["EMAIL"]    = existing.email_address
    ENV["PASSWORD"] = "newpassword"

    assert_no_difference "User.count" do
      Rake::Task["setup:admin"].invoke
    end

    existing.reload
    assert_equal "Updated Name", existing.name
    assert existing.authenticate("newpassword")
  ensure
    Rake::Task["setup:admin"].reenable
    ENV.delete("NAME")
    ENV.delete("EMAIL")
    ENV.delete("PASSWORD")
  end
end
