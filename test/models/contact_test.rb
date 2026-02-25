require "test_helper"

class ContactTest < ActiveSupport::TestCase
  test "valid with all required attributes" do
    contact = Contact.new(user: users(:one), name: "Test User", email: "test@example.com")
    assert contact.valid?
  end

  test "requires name" do
    contact = Contact.new(user: users(:one), email: "test@example.com")
    assert_not contact.valid?
    assert_includes contact.errors[:name], "can't be blank"
  end

  test "requires email" do
    contact = Contact.new(user: users(:one), name: "Test User")
    assert_not contact.valid?
    assert_includes contact.errors[:email], "can't be blank"
  end

  test "email unique scoped to user" do
    existing = contacts(:one_alice)
    duplicate = Contact.new(user: existing.user, name: "Other", email: existing.email)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:email], "has already been taken"
  end

  test "same email allowed for different users" do
    contact = Contact.new(user: users(:two), name: "Alice", email: contacts(:one_alice).email)
    assert contact.valid?
  end

  test "total_bookings_count defaults to 0" do
    contact = Contact.create!(user: users(:one), name: "New", email: "new@example.com")
    assert_equal 0, contact.total_bookings_count
  end
end
