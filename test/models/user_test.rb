require "test_helper"

class UserTest < ActiveSupport::TestCase
  def valid_attributes
    { email: "test@example.com", password: "Password1", name: "Test User", phone_number: "+391234567890" }
  end

  test "valid user is saved" do
    assert User.new(valid_attributes).valid?
  end

  test "email is required" do
    assert_not User.new(valid_attributes.merge(email: nil)).valid?
  end

  test "email must be unique case-insensitively" do
    User.create!(valid_attributes)
    duplicate = User.new(valid_attributes.merge(email: "TEST@example.com"))
    assert_not duplicate.valid?
  ensure
    User.find_by(email: "test@example.com")&.destroy
  end

  test "email must have valid format" do
    assert_not User.new(valid_attributes.merge(email: "not-an-email")).valid?
  end

  test "name is required" do
    assert_not User.new(valid_attributes.merge(name: nil)).valid?
  end

  test "phone number is required" do
    assert_not User.new(valid_attributes.merge(phone_number: nil)).valid?
  end

  test "password must be at least 8 characters" do
    assert_not User.new(valid_attributes.merge(password: "Pass1")).valid?
  end

  test "password must contain an uppercase letter" do
    assert_not User.new(valid_attributes.merge(password: "password1")).valid?
  end

  test "password must contain a number" do
    assert_not User.new(valid_attributes.merge(password: "Password")).valid?
  end
end
